import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import NotificationRepositoryImpl "../data/repositories/NotificationRepositoryImpl";
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
    type ReputationUpdateInfo = T.ReputationUpdateInfo;

    let updateReputationNamespace : Namespace = T.UPDATE_REPUTATION_NAMESPACE;
    // let increaseReputationNamespace : Namespace = T.INCREASE_REPUTATION_NAMESPACE;
    // let defaultCategory = T.DEFAULT_CATEGORY;

    // Repository implementations
    private var userRepo = UserRepositoryImpl.UserRepositoryImpl();
    private var reputationRepo = ReputationRepositoryImpl.ReputationRepositoryImpl();
    private var categoryRepo = CategoryRepositoryImpl.CategoryRepositoryImpl();
    private var notificationRepo = NotificationRepositoryImpl.NotificationRepositoryImpl();
    private let namespaceCategoryMapper = NamespaceCategoryMapper.NamespaceCategoryMapper(categoryRepo);

    // ICRC72 Client
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    // Use Cases
    private var useCaseFactory : ?UseCaseFactory.UseCaseFactory = null;

    // Initialize function to set up ICRC72 client
    public shared func initialize() : async () {
        let broadcaster = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(Principal.fromText(broadcaster), Principal.fromActor(Self));

        // Subscribe to reputation events
        switch (icrc72Client) {
            case (?client) {
                useCaseFactory := ?UseCaseFactory.UseCaseFactory(
                    userRepo,
                    reputationRepo,
                    categoryRepo,
                    notificationRepo,
                    client,
                    namespaceCategoryMapper,
                );
                ignore await client.subscribe(updateReputationNamespace);
                Debug.print("Subscribed to " # updateReputationNamespace);
            };
            case (null) {
                Debug.print("ICRC72 client not initialized");
            };
        };
    };

    // Handle incoming reputation events
    public func icrc72_handle_notification(notifications : [T.EventNotification]) : async () {
        switch (useCaseFactory) {
            case (?factory) {
                let handleNotificationUseCase = factory.getHandleNotificationUseCase();
                let notificationUseCase = factory.getNotificationUseCase();
                for (notification in notifications.vals()) {
                    await notificationUseCase.storeNotification(notification);
                    await handleNotificationUseCase.execute(notification);
                };
            };
            case (null) {
                Debug.print("UseCaseFactory not initialized");
            };
        };
    };

    // Update reputation
    public shared func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let updateReputationUseCase = factory.getUpdateReputationUseCase();
                let result = await updateReputationUseCase.execute(user, category, value);
                switch (result) {
                    case (#ok(_)) {
                        let publishEventUseCase = factory.getPublishEventUseCase();
                        await publishEventUseCase.publishReputationIncreaseEvent(
                            {
                                user = user;
                                category = ?category;
                                value = value;
                                verificationInfo = null;
                            },
                            Principal.fromActor(Self),
                        );
                    };
                    case _ {};
                };
                result;
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    // Get notifications for a specific namespace
    public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
        switch (useCaseFactory) {
            case (?factory) {
                let notificationUseCase = factory.getNotificationUseCase();
                await notificationUseCase.getNotifications(namespace);
            };
            case (null) {
                Debug.print("UseCaseFactory not initialized");
                [];
            };
        };
    };

    // ManageCategories use case methods
    public shared func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let manageCategoriesUseCase = factory.getManageCategoriesUseCase();
                await manageCategoriesUseCase.createCategory(id, name, description, parentId);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public func getCategory(id : CategoryId) : async Result.Result<Category.Category, Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let manageCategoriesUseCase = factory.getManageCategoriesUseCase();
                await manageCategoriesUseCase.getCategory(id);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let manageCategoriesUseCase = factory.getManageCategoriesUseCase();
                await manageCategoriesUseCase.updateCategory(category);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public func listCategories() : async [Category.Category] {
        switch (useCaseFactory) {
            case (?factory) {
                let manageCategoriesUseCase = factory.getManageCategoriesUseCase();
                await manageCategoriesUseCase.listCategories();
            };
            case (null) {
                Debug.print("UseCaseFactory not initialized");
                [];
            };
        };
    };

    // GetUserReputation use case methods
    public func getUserReputation(userId : User.UserId, categoryId : Category.CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let getUserReputationUseCase = factory.getGetUserReputationUseCase();
                await getUserReputationUseCase.execute(userId, categoryId);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public func getUserReputations(userId : UserId) : async Result.Result<[Reputation.Reputation], Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let getUserReputationUseCase = factory.getGetUserReputationUseCase();
                await getUserReputationUseCase.getUserReputations(userId);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
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
        switch (useCaseFactory) {
            case (?factory) {
                let deleteCategoryUseCase = factory.getDeleteCategoryUseCase();
                let result = await deleteCategoryUseCase.execute(categoryId);
                if (result) {
                    #ok(());
                } else {
                    #err("Failed to delete category");
                };
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
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
        switch (useCaseFactory) {
            case (?factory) {
                let clearAllDataUseCase = factory.getClearAllDataUseCase();
                await clearAllDataUseCase.execute();
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };
};
