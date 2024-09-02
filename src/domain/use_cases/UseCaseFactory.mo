import ICRC72Client "../../infrastructure/ICRC72Client";
import CategoryRepository "../repositories/CategoryRepository";
import NotificationRepository "../repositories/NotificationRepository";
import ReputationRepository "../repositories/ReputationRepository";
import UserRepository "../repositories/UserRepository";
import ReputationHistoryRepository "../repositories/ReputationHistoryRepository";
import NamespaceCategoryMappingRepository "../repositories/NamespaceCategoryMappingRepository";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import DocumentClassifier "../services/DocumentClassifier";

import ClearAllDataUseCase "./ClearAllDataUseCase";
import DeleteCategoryUseCase "./DeleteCategoryUseCase";
import DeleteUserUseCase "./DeleteUserUseCase";
import GetUserReputationUseCase "./GetUserReputation";
import HandleNotificationUseCase "./HandleNotificationUseCase";
import ManageCategoriesUseCase "./ManageCategoriesUseCase";
import NotificationUseCase "./NotificationUseCase";
import PublishEventUseCase "./PublishEventUseCase";
import ReputationHistoryUseCase "./ReputationHistoryUseCase";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import DetermineCategoriesUseCase "./DetermineCategoriesUseCase";

module {
    public class UseCaseFactory(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
        notificationRepo : NotificationRepository.NotificationRepository,
        reputationHistoryRepo : ReputationHistoryRepository.ReputationHistoryRepository,
        namespaceMappingRepo : NamespaceCategoryMappingRepository.NamespaceCategoryMappingRepository,
        icrc72Client : ICRC72Client.ICRC72ClientImpl,
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
        documentClassifier : DocumentClassifier.DocumentClassifier,
    ) {
        public func getManageCategoriesUseCase() : ManageCategoriesUseCase.ManageCategoriesUseCase {
            ManageCategoriesUseCase.ManageCategoriesUseCase(categoryRepo);
        };

        public func getUpdateReputationUseCase() : UpdateReputationUseCase.UpdateReputationUseCase {
            UpdateReputationUseCase.UpdateReputationUseCase(
                reputationRepo,
                userRepo,
                categoryRepo,
                getReputationHistoryUseCase(),
            );
        };

        public func getGetUserReputationUseCase() : GetUserReputationUseCase.GetUserReputationUseCase {
            GetUserReputationUseCase.GetUserReputationUseCase(reputationRepo);
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
            ReputationHistoryUseCase.ReputationHistoryUseCase(reputationHistoryRepo);
        };

        public func getNamespaceCategoryMapper() : NamespaceCategoryMapper.NamespaceCategoryMapper {
            namespaceCategoryMapper;
        };

        public func getDocumentClassifier() : DocumentClassifier.DocumentClassifier {
            documentClassifier;
        };

        public func getNamespaceCategoryMappingRepository() : NamespaceCategoryMappingRepository.NamespaceCategoryMappingRepository {
            namespaceMappingRepo;
        };

        public func getUserRepository() : UserRepository.UserRepository {
            userRepo;
        };

        public func getReputationRepository() : ReputationRepository.ReputationRepository {
            reputationRepo;
        };

        public func getCategoryRepository() : CategoryRepository.CategoryRepository {
            categoryRepo;
        };

        public func getNotificationRepository() : NotificationRepository.NotificationRepository {
            notificationRepo;
        };

        public func getReputationHistoryRepository() : ReputationHistoryRepository.ReputationHistoryRepository {
            reputationHistoryRepo;
        };

        public func getDetermineCategoriesUseCase() : DetermineCategoriesUseCase.DetermineCategoriesUseCase {
            DetermineCategoriesUseCase.DetermineCategoriesUseCase(
                namespaceCategoryMapper,
                documentClassifier,
                namespaceMappingRepo,
            );
        };
    };
};
