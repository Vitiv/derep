import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Category "../domain/entities/Category";
import Document "../domain/entities/Document";
import Reputation "../domain/entities/Reputation";
import T "../domain/entities/Types";
import User "../domain/entities/User";
import DetermineCategoriesUseCase "../domain/use_cases/DetermineCategoriesUseCase";
import ReputationHistoryUseCase "../domain/use_cases/ReputationHistoryUseCase";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import IncomingFile "../domain/entities/IncomingFile";

module {
    public class APIHandler(useCaseFactory : UseCaseFactory.UseCaseFactory) {
        public func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<Int, Text> {
            let updateReputationUseCase = useCaseFactory.getUpdateReputationUseCase();
            await updateReputationUseCase.execute(user, category, value);
        };

        public func processIncomingFile(file : IncomingFile.IncomingFile, caller : Principal) : async Result.Result<Document.DocumentId, Text> {
            let processIncomingFileUseCase = useCaseFactory.getProcessIncomingFileUseCase();
            await processIncomingFileUseCase.execute(file, caller);
        };

        public func verifyDocumentSource(documentId : Document.DocumentId, reviewer : Principal) : async Result.Result<(), Text> {
            let verifyDocumentSourceUseCase = useCaseFactory.getVerifyDocumentSourceUseCase();
            await verifyDocumentSourceUseCase.execute(documentId, reviewer);
        };

        public func updateDocumentCategories(documentId : Document.DocumentId, newCategories : [Text], caller : Principal) : async Result.Result<(), Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.updateDocumentCategories(documentId, newCategories, caller);
        };

        public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.getDocument(id);
        };

        public func updateDocument(doc : Document.Document) : async Result.Result<Int, Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.updateDocument(doc);
        };

        public func listUserDocuments(userId : Principal) : async Result.Result<[Document.Document], Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.listUserDocuments(userId);
        };

        public func deleteDocument(id : Document.DocumentId) : async Result.Result<(), Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.deleteDocument(id);
        };

        public func getDocumentVersions(id : Document.DocumentId) : async Result.Result<[Document.Document], Text> {
            let manageDocumentsUseCase = useCaseFactory.getManageDocumentsUseCase();
            await manageDocumentsUseCase.getDocumentVersions(id);
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
