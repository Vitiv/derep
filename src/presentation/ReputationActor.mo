import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Array "mo:base/Array";

import User "../domain/entities/User";
import Reputation "../domain/entities/Reputation";
import Category "../domain/entities/Category";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import ICRC72Client "../infrastructure/ICRC72Client";
import T "../domain/entities/Types";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";

actor class ReputationActor() = Self {
    type UserId = User.UserId;
    type CategoryId = Category.CategoryId;
    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;

    var defaultNamespace : Namespace = "update.reputation.ava";

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
    public shared func initialize(hubPrincipal : Principal) : async () {
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(hubPrincipal, Principal.fromActor(Self));

        // Subscribe to reputation events
        switch (icrc72Client) {
            case (?client) {
                ignore await client.subscribe(defaultNamespace);
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
            let handleReputationEventUseCase = useCaseFactory.getHandleReputationEventUseCase();
            handleReputationEventUseCase.execute(notification);
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
        useCase.getCategory(id);
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        useCase.updateCategory(category);
    };

    public func listCategories() : async [Category.Category] {
        let useCase = useCaseFactory.getManageCategoriesUseCase();
        useCase.listCategories();
    };

    // UpdateReputation use case method
    public shared func updateReputation(userId : UserId, categoryId : CategoryId, scoreChange : Int) : async Result.Result<(), Text> {
        let useCase = useCaseFactory.getUpdateReputationUseCase();
        useCase.execute(userId, categoryId, scoreChange);
    };

    // GetUserReputation use case methods
    public shared func getUserReputation(userId : UserId, categoryId : CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        let useCase = useCaseFactory.getGetUserReputationUseCase();
        useCase.execute(userId, categoryId);
    };

    public shared func getUserReputations(userId : UserId) : async Result.Result<[Reputation.Reputation], Text> {
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
