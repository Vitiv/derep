import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Array "mo:base/Array";

import User "../domain/entities/User";
import Reputation "../domain/entities/Reputation";
import Category "../domain/entities/Category";
import UserRepository "../domain/repositories/UserRepository";
import ReputationRepository "../domain/repositories/ReputationRepository";
import CategoryRepository "../domain/repositories/CategoryRepository";
import ICRC72Client "../infrastructure/ICRC72Client";
import T "../domain/entities/Types";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";

actor class ReputationActor() = Self {
    type UserId = User.UserId;
    type CategoryId = Category.CategoryId;
    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;

    var defaultNamespace : Namespace = "update.reputation.ava";

    // Repositories
    private var userRepo : ?UserRepository.UserRepository = null;
    private var reputationRepo : ?ReputationRepository.ReputationRepository = null;
    private var categoryRepo : ?CategoryRepository.CategoryRepository = null;

    // ICRC72 Client
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    // Use Cases
    private var useCaseFactory : ?UseCaseFactory.UseCaseFactory = null;

    // Local storage for categories
    private var categories = HashMap.HashMap<CategoryId, Category.Category>(10, Text.equal, Text.hash);

    // Storage for notifications
    private var notificationMap = HashMap.HashMap<Namespace, [EventNotification]>(10, Text.equal, Text.hash);

    // Initialize function to set up repositories, ICRC72 client, and use cases
    public shared func initialize(
        userRepoPrincipal : Principal,
        reputationRepoPrincipal : Principal,
        categoryRepoPrincipal : Principal,
        hubPrincipal : Principal,
    ) : async () {
        userRepo := ?actor (Principal.toText(userRepoPrincipal));
        reputationRepo := ?actor (Principal.toText(reputationRepoPrincipal));
        categoryRepo := ?actor (Principal.toText(categoryRepoPrincipal));

        useCaseFactory := ?UseCaseFactory.UseCaseFactory(
            Option.unwrap(userRepo),
            Option.unwrap(reputationRepo),
            Option.unwrap(categoryRepo),
        );

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
            switch (useCaseFactory) {
                case (?factory) {
                    let handleReputationEventUseCase = factory.getHandleReputationEventUseCase();
                    await handleReputationEventUseCase.execute(notification);
                };
                case (null) {
                    Debug.print("Use case factory not initialized");
                };
            };
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
        switch (useCaseFactory) {
            case (?factory) {
                let useCase = factory.getManageCategoriesUseCase();
                let result = await useCase.createCategory(id, name, description, parentId);
                switch (result) {
                    case (#ok(category)) {
                        categories.put(id, category);
                        #ok(category);
                    };
                    case (#err(e)) #err(e);
                };
            };
            case (null) {
                #err("Use case factory not initialized");
            };
        };
    };

    public query func getCategory(id : CategoryId) : async Result.Result<Category.Category, Text> {
        switch (categories.get(id)) {
            case (?category) #ok(category);
            case (null) #err("Category not found");
        };
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let useCase = factory.getManageCategoriesUseCase();
                let result = await useCase.updateCategory(category);
                switch (result) {
                    case (#ok(_)) {
                        categories.put(category.id, category);
                        #ok(());
                    };
                    case (#err(e)) #err(e);
                };
            };
            case (null) {
                #err("Use case factory not initialized");
            };
        };
    };

    public query func listCategories() : async [Category.Category] {
        Iter.toArray(categories.vals());
    };

    // UpdateReputation use case method
    public shared func updateReputation(userId : UserId, categoryId : CategoryId, scoreChange : Int) : async Result.Result<(), Text> {
        switch (useCaseFactory) {
            case (?factory) {
                let useCase = factory.getUpdateReputationUseCase();
                await useCase.execute(userId, categoryId, scoreChange);
            };
            case (null) {
                #err("Use case factory not initialized");
            };
        };
    };

    // GetUserReputation use case methods
    public shared func getUserReputation(userId : UserId, categoryId : CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        switch (reputationRepo) {
            case (?repo) {
                switch (await repo.getReputation(userId, categoryId)) {
                    case (?reputation) #ok(reputation);
                    case (null) #err("Reputation not found");
                };
            };
            case (null) {
                #err("Reputation repository not initialized");
            };
        };
    };

    public shared func getUserReputations(userId : UserId) : async Result.Result<[Reputation.Reputation], Text> {
        switch (reputationRepo) {
            case (?repo) {
                #ok(await repo.getUserReputations(userId));
            };
            case (null) {
                #err("Reputation repository not initialized");
            };
        };
    };

    // System methods
    system func preupgrade() {
        // TODO: Implement state preservation logic if needed
    };

    system func postupgrade() {
        // TODO: Implement state restoration logic if needed
    };
};
