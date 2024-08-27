// import VerificationActor "canister:ver";

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import Category "../domain/entities/Category";
import Reputation "../domain/entities/Reputation";
import T "../domain/entities/Types";
import User "../domain/entities/User";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import ICRC72Client "../infrastructure/ICRC72Client";

/// todo add broadcaster canister id bkyz2-fmaaa-aaaaa-qaaaq-cai

actor class ReputationActor() = Self {
    type UserId = User.UserId;
    type CategoryId = Category.CategoryId;
    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;
    type ReputationUpdateInfo = {
        user : Principal;
        category : Text;
        value : Int;
        verificationInfo : ?{
            canister : Principal;
            method : Text;
            documentId : Nat;
        };
    };

    let updateReputationNamespace : Namespace = "update.reputation.ava";
    let increaseReputationNamespace : Namespace = "increase.reputation.ava";

    // Repository implementations
    private let userRepo = UserRepositoryImpl.UserRepositoryImpl();
    private let reputationRepo = ReputationRepositoryImpl.ReputationRepositoryImpl();
    private let categoryRepo = CategoryRepositoryImpl.CategoryRepositoryImpl();

    // ICRC72 Client
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    // Use Cases
    private let useCaseFactory = UseCaseFactory.UseCaseFactory(userRepo, reputationRepo, categoryRepo);

    // Storage for notifications
    private var notificationMap = HashMap.HashMap<Namespace, [EventNotification]>(10, Text.equal, Text.hash);

    // Initialize function to set up ICRC72 client
    public shared func initialize() : async () {
        let broadcaster = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(Principal.fromText(broadcaster), Principal.fromActor(Self));

        // Subscribe to reputation events
        switch (icrc72Client) {
            case (?client) {
                ignore await client.subscribe(updateReputationNamespace);
                Debug.print("Subscribed to " # updateReputationNamespace);
            };
            case (null) {
                Debug.print("ICRC72 client not initialized");
            };
        };
    };

    // Handle incoming reputation events
    public func icrc72_handle_notification(notifications : [EventNotification]) : async () {
        Debug.print("Notifications received: " # Nat.toText(notifications.size()));
        for (notification in notifications.vals()) {
            Debug.print("Processing notification: " # debug_show (notification));

            // Store the notification
            storeNotification(notification);

            // Process the notification
            await processNotification(notification);
        };
    };

    // Store a notification
    private func storeNotification(notification : EventNotification) {
        let namespace = notification.namespace;
        switch (notificationMap.get(namespace)) {
            case null notificationMap.put(namespace, [notification]);
            case (?existingNotifications) {
                let newList = Array.append(existingNotifications, [notification]);
                notificationMap.put(namespace, newList);
            };
        };
    };

    // Process a notification
    private func processNotification(notification : EventNotification) : async () {
        if (notification.namespace == updateReputationNamespace) {
            let parseResult = parseReputationUpdateNotification(notification);
            switch (parseResult) {
                case (#ok(data)) {
                    // Validate the data
                    if (await validateReputationUpdate(data)) {
                        // Update reputation
                        let updateResult = await updateReputation(data.user, data.category, data.value);
                        switch (updateResult) {
                            case (#ok(_)) {
                                // Publish event about new reputation
                                await publishReputationIncreaseEvent(data);
                            };
                            case (#err(error)) {
                                Debug.print("Failed to update reputation: " # error);
                            };
                        };
                    } else {
                        Debug.print("Invalid reputation update data");
                    };
                };
                case (#err(error)) {
                    Debug.print("Failed to parse notification: " # error);
                };
            };
        };
    };

    // Parse reputation update notification
    private func parseReputationUpdateNotification(notification : EventNotification) : Result.Result<ReputationUpdateInfo, Text> {
        switch (notification.data) {
            case (#Map(dataMap)) {
                var user : ?Principal = null;
                var category : ?Text = null;
                var value : ?Int = null;
                var verificationCanister : ?Principal = null;
                var verificationMethod : ?Text = null;
                var documentId : ?Nat = null;

                for ((key, val) in dataMap.vals()) {
                    switch (key, val) {
                        case ("user", #Principal(p)) { user := ?p };
                        case ("category", #Text(t)) { category := ?t };
                        case ("value", #Int(i)) { value := ?i };
                        case ("verificationCanister", #Principal(p)) {
                            verificationCanister := ?p;
                        };
                        case ("verificationMethod", #Text(t)) {
                            verificationMethod := ?t;
                        };
                        case ("documentId", #Nat(n)) { documentId := ?n };
                        case _ { /* Ignore other fields */ };
                    };
                };

                switch (user, category, value, verificationCanister, verificationMethod, documentId) {
                    case (?u, ?c, ?v, ?vc, ?vm, ?d) {
                        #ok({
                            user = u;
                            category = c;
                            value = v;
                            verificationInfo = ?{
                                canister = vc;
                                method = vm;
                                documentId = d;
                            };
                        });
                    };
                    case _ {
                        #err("Invalid or incomplete data in reputation update notification");
                    };
                };
            };
            case _ {
                #err("Unexpected data format in reputation update notification");
            };
        };
    };

    // Validate reputation update
    private func validateReputationUpdate(data : ReputationUpdateInfo) : async Bool {
        // Check if the category exists
        let categoryResult = await getCategory(data.category);
        switch (categoryResult) {
            case (#err(_)) { return false };
            case (#ok(_)) {};
        };

        // Check if the user exists
        let userOpt = await getUser(data.user);
        switch (userOpt) {
            case null { return false };
            case (?_) {};
        };

        // Call the verification method on the verification canister
        switch (data.verificationInfo) {
            case (null) { return false };
            case (?info) {
                try {
                    // let verificationActor = actor (Principal.toText(info.canister)) : actor {
                    //     verify : (Nat) -> async Bool;
                    // };
                    return true; //await VerificationActor.verify(info.documentId);
                } catch (error) {
                    Debug.print("Error calling verification method: " # Error.message(error));
                    return false;
                };
            };
        };
    };

    // Update reputation
    private func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
        let updateReputationUseCase = useCaseFactory.getUpdateReputationUseCase();
        updateReputationUseCase.execute(user, category, value);
    };

    // Publish reputation increase event
    private func publishReputationIncreaseEvent(data : ReputationUpdateInfo) : async () {
        switch (icrc72Client) {
            case (?client) {
                let event : T.Event = {
                    id = 1;
                    prevId = null;
                    timestamp = Int.abs(Time.now());
                    namespace = increaseReputationNamespace;
                    headers = null;
                    data = #Map([
                        ("user", #Principal(data.user)),
                        ("category", #Text(data.category)),
                        ("value", #Int(data.value)),
                    ]);
                    source = Principal.fromActor(Self);
                };
                ignore await client.publish(event);
                Debug.print("Published reputation increase event");
            };
            case (null) {
                Debug.print("ICRC72 client not initialized, couldn't publish event");
            };
        };
    };

    // Get notifications for a specific namespace
    public query func getNotifications(namespace : Namespace) : async [EventNotification] {
        Option.get(notificationMap.get(namespace), []);
    };

    // ManageCategories use case methods
    public shared func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        await useCase.createCategory(id, name, description, parentId);
    };

    public query func getCategory(id : CategoryId) : async Result.Result<Category.Category, Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        useCase.getCategory(id);
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        useCase.updateCategory(category);
    };

    public query func listCategories() : async [Category.Category] {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        useCase.listCategories();
    };

    // GetUserReputation use case methods
    public query func getUserReputation(userId : UserId, categoryId : CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        let useCase = useCaseFactory.getGetUserReputationUseCase();
        useCase.execute(userId, categoryId);
    };

    public query func getUserReputations(userId : UserId) : async Result.Result<[Reputation.Reputation], Text> {
        let useCase = useCaseFactory.getGetUserReputationUseCase();
        useCase.getUserReputations(userId);
    };

    // Additional methods using repository implementations directly

    public shared func createUser(user : User.User) : async Bool {
        userRepo.createUser(user);
    };

    public query func getUser(userId : UserId) : async ?User.User {
        userRepo.getUser(userId);
    };

    public shared func updateUser(user : User.User) : async Bool {
        userRepo.updateUser(user);
    };

    public shared func deleteUser(userId : UserId) : async Bool {
        userRepo.deleteUser(userId);
    };

    public query func listUsers() : async [User.User] {
        userRepo.listUsers();
    };

    public query func getUsersByUsername(username : Text) : async [User.User] {
        userRepo.getUsersByUsername(username);
    };

    public query func getAllReputations() : async [Reputation.Reputation] {
        reputationRepo.getAllReputations();
    };

    public query func getTopUsersByCategoryId(categoryId : CategoryId, limit : Nat) : async [(UserId, Int)] {
        reputationRepo.getTopUsersByCategoryId(categoryId, limit);
    };

    public query func getTotalUserReputation(userId : UserId) : async Int {
        reputationRepo.getTotalUserReputation(userId);
    };

    // System methods
    system func preupgrade() {
        // Implement state preservation logic if needed
    };

    system func postupgrade() {
        // Implement state restoration logic if needed
    };
};