import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Category "../domain/entities/Category";
import Reputation "../domain/entities/Reputation";
import User "../domain/entities/User";
import T "../domain/entities/Types";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import ReputationHistoryUseCase "../domain/use_cases/ReputationHistoryUseCase";
import DetermineCategoriesUseCase "../domain/use_cases/DetermineCategoriesUseCase";

module {
    public class APIHandler(useCaseFactory : UseCaseFactory.UseCaseFactory) {
        public func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<(), Text> {
            let updateReputationUseCase = useCaseFactory.getUpdateReputationUseCase();
            await updateReputationUseCase.execute(user, category, value);
        };

        public func getReputationHistoryUseCase() : ReputationHistoryUseCase.ReputationHistoryUseCase {
            useCaseFactory.getReputationHistoryUseCase();
        };

        public func getUserReputation(userId : User.UserId, categoryId : Category.CategoryId) : async Result.Result<Reputation.Reputation, Text> {
            let getUserReputationUseCase = useCaseFactory.getGetUserReputationUseCase();
            await getUserReputationUseCase.execute(userId, categoryId);
        };

        public func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
            let manageCategoriesUseCase = useCaseFactory.getManageCategoriesUseCase();
            await manageCategoriesUseCase.createCategory(id, name, description, parentId);
        };

        public func getCategory(id : Category.CategoryId) : async Result.Result<Category.Category, Text> {
            let manageCategoriesUseCase = useCaseFactory.getManageCategoriesUseCase();
            await manageCategoriesUseCase.getCategory(id);
        };

        public func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
            let manageCategoriesUseCase = useCaseFactory.getManageCategoriesUseCase();
            await manageCategoriesUseCase.updateCategory(category);
        };

        public func listCategories() : async [Category.Category] {
            let manageCategoriesUseCase = useCaseFactory.getManageCategoriesUseCase();
            await manageCategoriesUseCase.listCategories();
        };

        public func createUser(user : User.User) : async Result.Result<Bool, Text> {
            let userRepo = useCaseFactory.getUserRepository();
            let result = await userRepo.createUser(user);
            #ok(result);
        };

        public func getUser(userId : User.UserId) : async Result.Result<?User.User, Text> {
            let userRepo = useCaseFactory.getUserRepository();
            let user = await userRepo.getUser(userId);
            #ok(user);
        };

        public func updateUser(user : User.User) : async Result.Result<Bool, Text> {
            let userRepo = useCaseFactory.getUserRepository();
            let result = await userRepo.updateUser(user);
            #ok(result);
        };

        public func deleteUser(userId : User.UserId) : async Result.Result<(), Text> {
            let deleteUserUseCase = useCaseFactory.getDeleteUserUseCase();
            let result = await deleteUserUseCase.execute(userId);
            if (result) {
                #ok(());
            } else {
                #err("Failed to delete user");
            };
        };

        public func deleteCategory(categoryId : Category.CategoryId) : async Result.Result<(), Text> {
            let deleteCategoryUseCase = useCaseFactory.getDeleteCategoryUseCase();
            let result = await deleteCategoryUseCase.execute(categoryId);
            if (result) {
                #ok(());
            } else {
                #err("Failed to delete category");
            };
        };

        public func listUsers() : async Result.Result<[User.User], Text> {
            let userRepo = useCaseFactory.getUserRepository();
            let users = await userRepo.listUsers();
            #ok(users);
        };

        public func getUsersByUsername(username : Text) : async Result.Result<[User.User], Text> {
            let userRepo = useCaseFactory.getUserRepository();
            let users = await userRepo.getUsersByUsername(username);
            #ok(users);
        };

        public func getAllReputations() : async Result.Result<[Reputation.Reputation], Text> {
            let reputationRepo = useCaseFactory.getReputationRepository();
            let reputations = await reputationRepo.getAllReputations();
            #ok(reputations);
        };

        public func getTopUsersByCategoryId(categoryId : Category.CategoryId, limit : Nat) : async Result.Result<[(User.UserId, Int)], Text> {
            let reputationRepo = useCaseFactory.getReputationRepository();
            let topUsers = await reputationRepo.getTopUsersByCategoryId(categoryId, limit);
            #ok(topUsers);
        };

        public func getTotalUserReputation(userId : User.UserId) : async Result.Result<Int, Text> {
            let reputationRepo = useCaseFactory.getReputationRepository();
            let totalReputation = await reputationRepo.getTotalUserReputation(userId);
            #ok(totalReputation);
        };

        public func clearAllData() : async Result.Result<(), Text> {
            let clearAllDataUseCase = useCaseFactory.getClearAllDataUseCase();
            await clearAllDataUseCase.execute();
        };

        public func handleNotification(notifications : [T.EventNotification]) : async () {
            let handleNotificationUseCase = useCaseFactory.getHandleNotificationUseCase();
            let notificationUseCase = useCaseFactory.getNotificationUseCase();
            for (notification in notifications.vals()) {
                await notificationUseCase.storeNotification(notification);
                await handleNotificationUseCase.execute(notification);
            };
        };

        public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
            let notificationUseCase = useCaseFactory.getNotificationUseCase();
            await notificationUseCase.getNotifications(namespace);
        };

        public func getNamespacesForCategory(categoryId : Category.CategoryId) : async [Text] {
            let namespaceMappingRepo = useCaseFactory.getNamespaceCategoryMappingRepository();
            await namespaceMappingRepo.getNamespacesForCategory(categoryId);
        };
        public func getDetermineCategoriesUseCase() : DetermineCategoriesUseCase.DetermineCategoriesUseCase {
            useCaseFactory.getDetermineCategoriesUseCase();
        };
    };
};
