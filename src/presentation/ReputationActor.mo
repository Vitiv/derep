import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import NotificationRepositoryImpl "../data/repositories/NotificationRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import Category "../domain/entities/Category";
import Reputation "../domain/entities/Reputation";
import T "../domain/entities/Types";
import User "../domain/entities/User";
import NamespaceCategoryMapper "../domain/services/NamespaceCategoryMapper";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import ICRC72Client "../infrastructure/ICRC72Client";
import APIHandler "./APIHandler";

actor class ReputationActor() = Self {
    private var apiHandler : ?APIHandler.APIHandler = null;
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    public shared func initialize() : async () {
        let userRepo = UserRepositoryImpl.UserRepositoryImpl();
        let reputationRepo = ReputationRepositoryImpl.ReputationRepositoryImpl();
        let categoryRepo = CategoryRepositoryImpl.CategoryRepositoryImpl();
        let notificationRepo = NotificationRepositoryImpl.NotificationRepositoryImpl();
        let namespaceCategoryMapper = NamespaceCategoryMapper.NamespaceCategoryMapper(categoryRepo);

        let broadcaster = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); // TODO set real broadcaster id
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(broadcaster, Principal.fromActor(Self));

        let useCaseFactory = UseCaseFactory.UseCaseFactory(
            userRepo,
            reputationRepo,
            categoryRepo,
            notificationRepo,
            Option.unwrap(icrc72Client),
            namespaceCategoryMapper,
        );

        apiHandler := ?APIHandler.APIHandler(useCaseFactory);

        switch (icrc72Client) {
            case (?client) {
                ignore await client.subscribe(T.UPDATE_REPUTATION_NAMESPACE);
                Debug.print("Subscribed to " # T.UPDATE_REPUTATION_NAMESPACE);
            };
            case (null) {
                Debug.print("ICRC72 client not initialized");
            };
        };
    };

    public shared func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.updateReputation(user, category, value);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUserReputation(userId : User.UserId, categoryId : Category.CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.getUserReputation(userId, categoryId);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.createCategory(id, name, description, parentId);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getCategory(id : Category.CategoryId) : async Result.Result<Category.Category, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getCategory(id) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.updateCategory(category) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func listCategories() : async [Category.Category] {
        switch (apiHandler) {
            case (?handler) { await handler.listCategories() };
            case (null) { [] };
        };
    };

    public shared func createUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.createUser(user) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUser(userId : User.UserId) : async Result.Result<?User.User, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getUser(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func updateUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.updateUser(user) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func deleteUser(userId : User.UserId) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.deleteUser(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func deleteCategory(categoryId : Category.CategoryId) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.deleteCategory(categoryId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func listUsers() : async Result.Result<[User.User], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.listUsers() };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUsersByUsername(username : Text) : async Result.Result<[User.User], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getUsersByUsername(username) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getAllReputations() : async Result.Result<[Reputation.Reputation], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getAllReputations() };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getTopUsersByCategoryId(categoryId : Category.CategoryId, limit : Nat) : async Result.Result<[(User.UserId, Int)], Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.getTopUsersByCategoryId(categoryId, limit);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getTotalUserReputation(userId : User.UserId) : async Result.Result<Int, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getTotalUserReputation(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func clearAllData() : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.clearAllData() };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func icrc72_handle_notification(notifications : [T.EventNotification]) : async () {
        switch (apiHandler) {
            case (?handler) { await handler.handleNotification(notifications) };
            case (null) { Debug.print("API Handler not initialized") };
        };
    };

    public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
        switch (apiHandler) {
            case (?handler) { await handler.getNotifications(namespace) };
            case (null) { [] };
        };
    };

    // System methods remain unchanged
    system func preupgrade() {
        // Implement state preservation logic if needed
    };

    system func postupgrade() {
        // Implement state restoration logic if needed
    };
};
