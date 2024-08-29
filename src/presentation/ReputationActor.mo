// import VerificationActor "canister:ver";

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

import ArrayUtils "../../utils/ArrayUtils";
import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import Category "../domain/entities/Category";
import Reputation "../domain/entities/Reputation";
import T "../domain/entities/Types";
import User "../domain/entities/User";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import ICRC72Client "../infrastructure/ICRC72Client";
import NamespaceCategoryMapper "../domain/services/NamespaceCategoryMapper";

actor class ReputationActor() = Self {
    type UserId = User.UserId;
    type CategoryId = Category.CategoryId;
    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;
    type ReputationUpdateInfo = {
        user : Principal;
        category : ?Text;
        value : Int;
        verificationInfo : ?{
            canister : Principal;
            method : Text;
            documentId : Nat;
        };
    };

    let updateReputationNamespace : Namespace = "update.reputation.ava";
    let increaseReputationNamespace : Namespace = "increase.reputation.ava";
    let defaultCategory = "common.ava";

    // Repository implementations
    private var userRepo = UserRepositoryImpl.UserRepositoryImpl();
    private var reputationRepo = ReputationRepositoryImpl.ReputationRepositoryImpl();
    private var categoryRepo = CategoryRepositoryImpl.CategoryRepositoryImpl();
    private let namespaceCategoryMapper = NamespaceCategoryMapper.NamespaceCategoryMapper(categoryRepo);

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
                let newList = ArrayUtils.appendArray(existingNotifications, [notification]);
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
                    // Get categories from namespace
                    let categories = await namespaceCategoryMapper.mapNamespaceToCategories(notification.namespace);

                    let categoriesToUpdate = if (categories.size() > 0) {
                        categories;
                    } else {
                        // if no category found
                        switch (data.category) {
                            case null { [] };
                            case (?cat) { [cat] };
                        };
                    };

                    // Validate the data
                    if (await validateReputationUpdate(data)) {
                        // Update reputation for all matched categories
                        for (category in categoriesToUpdate.vals()) {
                            let updateResult = await updateReputation(data.user, category, data.value);
                            switch (updateResult) {
                                case (#ok(_)) {
                                    // Update parent categories
                                    let parentCategories = await namespaceCategoryMapper.getParentCategories(category);
                                    for (parentCategory in parentCategories.vals()) {
                                        ignore await updateReputation(data.user, parentCategory, data.value);
                                    };

                                    // Publish event about new reputation
                                    await publishReputationIncreaseEvent({
                                        data with category = ?category
                                    });
                                };
                                case (#err(error)) {
                                    Debug.print("Failed to update reputation for category " # category # ": " # error);
                                };
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
                    case (?u, c, ?v, ?vc, ?vm, ?d) {
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
        // Check if the user exists
        let userOpt = await getUser(data.user);
        switch (userOpt) {
            case null { return false };
            case (?_) {};
        };

        // Call the verification method on the verification canister
        switch (data.verificationInfo) {
            case (null) { return false };
            case (?_) {
                try {
                    // let verificationActor = actor (Principal.toText(info.canister)) : actor {
                    //     verify : (Nat) -> async Bool;
                    // };
                    return true; // await verificationActor.verify(info.documentId);
                } catch (error) {
                    Debug.print("Error calling verification method: " # Error.message(error));
                    return false;
                };
            };
        };

        true;
    };

    // Update reputation
    private func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
        let updateReputationUseCase = useCaseFactory.getUpdateReputationUseCase();
        await updateReputationUseCase.execute(user, category, value);
    };

    // Publish reputation increase event
    private func publishReputationIncreaseEvent(data : ReputationUpdateInfo) : async () {
        let categoryIncrease = Option.get(data.category, defaultCategory);
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
                        ("category", #Text(categoryIncrease)),
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

    public func getCategory(id : CategoryId) : async Result.Result<Category.Category, Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        await useCase.getCategory(id);
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        await useCase.updateCategory(category);
    };

    public func listCategories() : async [Category.Category] {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        await useCase.listCategories();
    };

    // GetUserReputation use case methods
    public func getUserReputation(userId : UserId, categoryId : CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        let useCase = useCaseFactory.getGetUserReputationUseCase();
        await useCase.execute(userId, categoryId);
    };

    public func getUserReputations(userId : UserId) : async Result.Result<[Reputation.Reputation], Text> {
        let useCase = useCaseFactory.getGetUserReputationUseCase();
        await useCase.getUserReputations(userId);
    };

    // Additional methods using repository implementations directly

    public shared func createUser(user : User.User) : async Bool {
        await userRepo.createUser(user);
    };

    public func getUser(userId : UserId) : async ?User.User {
        await userRepo.getUser(userId);
    };

    public shared func updateUser(user : User.User) : async Bool {
        await userRepo.updateUser(user);
    };

    public shared func deleteUser(userId : UserId) : async Result.Result<(), Text> {
        let deleteUserResult = await userRepo.deleteUser(userId);
        if (not deleteUserResult) {
            return #err("Failed to delete user");
        };

        let deleteReputationsResult = await reputationRepo.deleteUserReputations(userId);
        if (not deleteReputationsResult) {
            return #err("Failed to delete user reputations");
        };

        #ok(());
    };

    public shared func deleteCategory(categoryId : CategoryId) : async Result.Result<(), Text> {
        let deleteCategoryUseCase = useCaseFactory.getDeleteCategoryUseCase();
        let result = await deleteCategoryUseCase.execute(categoryId);
        if (result) {
            #ok(());
        } else {
            #err("Failed to delete category");
        };
    };

    public func listUsers() : async [User.User] {
        await userRepo.listUsers();
    };

    public func getUsersByUsername(username : Text) : async [User.User] {
        await userRepo.getUsersByUsername(username);
    };

    public func getAllReputations() : async [Reputation.Reputation] {
        await reputationRepo.getAllReputations();
    };

    public func getTopUsersByCategoryId(categoryId : CategoryId, limit : Nat) : async [(UserId, Int)] {
        await reputationRepo.getTopUsersByCategoryId(categoryId, limit);
    };

    public func getTotalUserReputation(userId : UserId) : async Int {
        await reputationRepo.getTotalUserReputation(userId);
    };

    // System methods
    system func preupgrade() {
        // Implement state preservation logic if needed
    };

    system func postupgrade() {
        // Implement state restoration logic if needed
    };

    public func clearAllData() : async Result.Result<(), Text> {
        // if (Principal.isAnonymous(caller)) {
        //     return #err("Anonymous principal not allowed");
        // };

        // Clear user data
        let userClearResult = await userRepo.clearAllUsers();
        if (not userClearResult) {
            return #err("Failed to clear user data");
        };

        // Clear reputation data
        let reputationClearResult = await reputationRepo.clearAllReputations();
        if (not reputationClearResult) {
            return #err("Failed to clear reputation data");
        };

        // Clear category data
        let categoryClearResult = await categoryRepo.clearAllCategories();
        if (not categoryClearResult) {
            return #err("Failed to clear category data");
        };

        // Clear notification map
        notificationMap := HashMap.HashMap<Namespace, [EventNotification]>(10, Text.equal, Text.hash);

        #ok(());
    };
};
