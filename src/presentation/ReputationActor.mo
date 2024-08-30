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

import UserRepository "../domain/repositories/UserRepository";
import ReputationRepository "../domain/repositories/ReputationRepository";
import CategoryRepository "../domain/repositories/CategoryRepository";
import NotificationRepository "../domain/repositories/NotificationRepository";

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
    private var userRepo : ?UserRepository.UserRepository = null;
    private var reputationRepo : ?ReputationRepository.ReputationRepository = null;
    private var categoryRepo : ?CategoryRepository.CategoryRepository = null;
    private var notificationRepo : ?NotificationRepository.NotificationRepository = null;
    private var namespaceCategoryMapper : ?NamespaceCategoryMapper.NamespaceCategoryMapper = null;

    // ICRC72 Client
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    // Use Cases
    private var useCaseFactory : ?UseCaseFactory.UseCaseFactory = null;

    // Initialize function to set up repositories, ICRC72 client, and use case factory
    public shared func initialize() : async () {
        userRepo := ?UserRepositoryImpl.UserRepositoryImpl();
        reputationRepo := ?ReputationRepositoryImpl.ReputationRepositoryImpl();
        categoryRepo := ?CategoryRepositoryImpl.CategoryRepositoryImpl();
        notificationRepo := ?NotificationRepositoryImpl.NotificationRepositoryImpl();

        switch (categoryRepo) {
            case (?repo) {
                namespaceCategoryMapper := ?NamespaceCategoryMapper.NamespaceCategoryMapper(repo);
            };
            case (null) {
                Debug.print("Category repository not initialized");
            };
        };

        let broadcaster = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(Principal.fromText(broadcaster), Principal.fromActor(Self));

        // Subscribe to reputation events
        switch (icrc72Client) {
            case (?client) {
                switch (userRepo, reputationRepo, categoryRepo, notificationRepo, namespaceCategoryMapper) {
                    case (?u, ?r, ?c, ?n, ?m) {
                        useCaseFactory := ?UseCaseFactory.UseCaseFactory(
                            u,
                            r,
                            c,
                            n,
                            client,
                            m,
                        );
                        ignore await client.subscribe(updateReputationNamespace);
                        Debug.print("initialize: Subscribed to " # updateReputationNamespace);
                    };
                    case _ {
                        Debug.print("initialize: One or more repositories not initialized");
                    };
                };
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
                await updateReputationUseCase.execute(user, category, value);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    // public shared func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
    //     switch (useCaseFactory) {
    //         case (?factory) {
    //             let updateReputationUseCase = factory.getUpdateReputationUseCase();
    //             let result = await updateReputationUseCase.execute(user, category, value);
    //             switch (result) {
    //                 case (#ok(_)) {
    //                     let publishEventUseCase = factory.getPublishEventUseCase();
    //                     await publishEventUseCase.publishReputationIncreaseEvent(
    //                         {
    //                             user = user;
    //                             category = ?category;
    //                             value = value;
    //                             verificationInfo = null;
    //                         },
    //                         Principal.fromActor(Self),
    //                     );
    //                 };
    //                 case _ {};
    //             };
    //             result;
    //         };
    //         case (null) {
    //             #err("UseCaseFactory not initialized");
    //         };
    //     };
    // };

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

    public shared func createUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (userRepo) {
            case (?repo) {
                let result = await repo.createUser(user);
                #ok(result);
            };
            case null {
                #err("User repository not initialized");
            };
        };
    };

    public func getUser(userId : UserId) : async Result.Result<?User.User, Text> {
        switch (userRepo) {
            case (?repo) {
                let user = await repo.getUser(userId);
                #ok(user);
            };
            case null {
                #err("User repository not initialized");
            };
        };
    };

    public shared func updateUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (userRepo) {
            case (?repo) {
                let result = await repo.updateUser(user);
                #ok(result);
            };
            case null {
                #err("User repository not initialized");
            };
        };
    };

    public shared func deleteUser(userId : UserId) : async Result.Result<(), Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let deleteUserUseCase = factory.getDeleteUserUseCase();
                let result = await deleteUserUseCase.execute(userId);
                if (result) {
                    #ok(());
                } else {
                    #err("Failed to delete user");
                };
            };
            case null {
                #err("UseCaseFactory not initialized");
            };
        };
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

    public func listUsers() : async Result.Result<[User.User], Text> {
        switch (userRepo) {
            case (?repo) {
                let users = await repo.listUsers();
                #ok(users);
            };
            case null {
                #err("User repository not initialized");
            };
        };
    };

    public func getUsersByUsername(username : Text) : async Result.Result<[User.User], Text> {
        switch (userRepo) {
            case (?repo) {
                let users = await repo.getUsersByUsername(username);
                #ok(users);
            };
            case null {
                #err("User repository not initialized");
            };
        };
    };

    public func getAllReputations() : async Result.Result<[Reputation.Reputation], Text> {
        switch (reputationRepo) {
            case (?repo) {
                let reputations = await repo.getAllReputations();
                #ok(reputations);
            };
            case null {
                #err("Reputation repository not initialized");
            };
        };
    };

    public func getTopUsersByCategoryId(categoryId : CategoryId, limit : Nat) : async Result.Result<[(UserId, Int)], Text> {
        switch (reputationRepo) {
            case (?repo) {
                let topUsers = await repo.getTopUsersByCategoryId(categoryId, limit);
                #ok(topUsers);
            };
            case null {
                #err("Reputation repository not initialized");
            };
        };
    };

    public func getTotalUserReputation(userId : UserId) : async Result.Result<Int, Text> {
        switch (reputationRepo) {
            case (?repo) {
                let totalReputation = await repo.getTotalUserReputation(userId);
                #ok(totalReputation);
            };
            case null {
                #err("Reputation repository not initialized");
            };
        };
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
