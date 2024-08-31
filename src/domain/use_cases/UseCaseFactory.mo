import Debug "mo:base/Debug";
import Int "mo:base/Int";

import InitialCategories "../../data/datasources/InitialCategories";
import ICRC72Client "../../infrastructure/ICRC72Client";
import CategoryRepository "../repositories/CategoryRepository";
import NotificationRepository "../repositories/NotificationRepository";
import ReputationHistoryRepository "../repositories/ReputationHistoryRepository";
import ReputationRepository "../repositories/ReputationRepository";
import UserRepository "../repositories/UserRepository";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import ClearAllDataUseCase "./ClearAllDataUseCase";
import DeleteCategoryUseCase "./DeleteCategoryUseCase";
import DeleteUserUseCase "./DeleteUserUseCase";
import GetUserReputation "./GetUserReputation";
import ManageCategories "./ManageCategoriesUseCase";
import NotificationUseCase "./NotificationUseCase";
import PublishEventUseCase "./PublishEventUseCase";
import ReputationHistoryUseCase "./ReputationHistoryUseCase";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import HandleNotificationUseCase "HandleNotificationUseCase";

module {
    public class UseCaseFactory(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
        notificationRepo : NotificationRepository.NotificationRepository,
        reputationHistoryRepo : ReputationHistoryRepository.ReputationHistoryRepository,
        icrc72Client : ICRC72Client.ICRC72ClientImpl,
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
    ) {
        public func areCategoriesInitialized() : async Bool {
            let categories = await categoryRepo.listCategories();
            categories.size() > 0;
        };

        public func initializeCategories() : async () {
            let flatCategories = InitialCategories.flattenCategories(InitialCategories.initialCategories);
            for (category in flatCategories.vals()) {
                switch (await categoryRepo.getCategory(category.id)) {
                    case (null) {
                        let result = await categoryRepo.createCategory(category);
                        if (result) {
                            Debug.print("Category created: " # category.id);
                        } else {
                            Debug.print("Failed to create category: " # category.id);
                        };
                    };
                    case (?existingCategory) {
                        Debug.print("Category already exists: " # debug_show (existingCategory));
                    };
                };
            };

            // Verify all categories after initialization
            for (category in flatCategories.vals()) {
                switch (await categoryRepo.getCategory(category.id)) {
                    case (null) {
                        Debug.print("ERROR: Category not found after initialization: " # category.id);
                    };
                    case (?_) {
                        Debug.print("Verified category exists: " # category.id);
                    };
                };
            };
            Debug.print("UseCaseFactory.initializeCategories: Initialization completed. Total categories: " # Int.toText(flatCategories.size()));

        };

        public func getManageCategoriesUseCase() : ManageCategories.ManageCategoriesUseCase {
            ManageCategories.ManageCategoriesUseCase(categoryRepo);
        };

        public func getUpdateReputationUseCase() : UpdateReputationUseCase.UpdateReputationUseCase {
            UpdateReputationUseCase.UpdateReputationUseCase(
                reputationRepo,
                userRepo,
                getReputationHistoryUseCase(),
            );
        };

        public func getReputationRepository() : ReputationRepository.ReputationRepository {
            reputationRepo;
        };

        public func getUserRepository() : UserRepository.UserRepository {
            userRepo;
        };

        public func getGetUserReputationUseCase() : GetUserReputation.GetUserReputationUseCase {
            GetUserReputation.GetUserReputationUseCase(reputationRepo);
        };

        public func getHandleNotificationUseCase() : HandleNotificationUseCase.HandleNotificationUseCase {
            HandleNotificationUseCase.HandleNotificationUseCase(
                namespaceCategoryMapper,
                getUpdateReputationUseCase(),
                categoryRepo,
            );
        };

        public func getPublishEventUseCase() : PublishEventUseCase.PublishEventUseCase {
            PublishEventUseCase.PublishEventUseCase(icrc72Client);
        };

        public func getDeleteUserUseCase() : DeleteUserUseCase.DeleteUserUseCase {
            DeleteUserUseCase.DeleteUserUseCase(userRepo, reputationRepo);
        };

        public func getDeleteCategoryUseCase() : DeleteCategoryUseCase.DeleteCategoryUseCase {
            DeleteCategoryUseCase.DeleteCategoryUseCase(categoryRepo, reputationRepo);
        };

        public func getNotificationUseCase() : NotificationUseCase.NotificationUseCase {
            NotificationUseCase.NotificationUseCase(notificationRepo);
        };

        public func getClearAllDataUseCase() : ClearAllDataUseCase.ClearAllDataUseCase {
            ClearAllDataUseCase.ClearAllDataUseCase(
                userRepo,
                reputationRepo,
                categoryRepo,
                notificationRepo,
            );
        };

        public func getReputationHistoryUseCase() : ReputationHistoryUseCase.ReputationHistoryUseCase {
            ReputationHistoryUseCase.ReputationHistoryUseCase(
                reputationHistoryRepo
            );
        };
    };
};
