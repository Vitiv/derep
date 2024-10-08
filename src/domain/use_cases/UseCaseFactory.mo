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
import DocumentRepository "../repositories/DocumentRepository";
import ManageDocumentsUseCase "./ManageDocumentsUseCase";
import ProcessIncomingFileUseCase "./ProcessIncomingFileUseCase";
import VerifyDocumentSourceUseCase "./VerifyDocumentSourceUseCase";

import VerifierWhitelistRepository "../repositories/VerifierWhitelistRepository";
import VerifierWhitelistRepositoryImpl "../../data/repositories/VerifierWhitelistRepositoryImpl";
import AddToWhitelistUseCase "./AddToWhitelistUseCase";
import RemoveFromWhitelistUseCase "./RemoveFromWhitelistUseCase";
import CheckWhitelistUseCase "./CheckWhitelistUseCase";
import GetWhitelistUseCase "./GetWhitelistUseCase";

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
        documentRepo : DocumentRepository.DocumentRepository,
    ) {
        public func getHandleNotificationUseCase() : HandleNotificationUseCase.HandleNotificationUseCase {
            HandleNotificationUseCase.HandleNotificationUseCase(
                namespaceCategoryMapper,
                getUpdateReputationUseCase(),
                categoryRepo,
                documentRepo,
            );
        };

        public func getManageCategoriesUseCase() : ManageCategoriesUseCase.ManageCategoriesUseCase {
            ManageCategoriesUseCase.ManageCategoriesUseCase(categoryRepo);
        };

        public func getManageDocumentsUseCase() : ManageDocumentsUseCase.ManageDocumentsUseCase {
            ManageDocumentsUseCase.ManageDocumentsUseCase(documentRepo);
        };

        public func getProcessIncomingFileUseCase() : ProcessIncomingFileUseCase.ProcessIncomingFileUseCase {
            ProcessIncomingFileUseCase.ProcessIncomingFileUseCase(documentRepo, getUpdateReputationUseCase(), userRepo, categoryRepo);
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

        public func getICRC72Client() : ICRC72Client.ICRC72ClientImpl {
            icrc72Client;
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

        public func getDocumentRepository() : DocumentRepository.DocumentRepository {
            documentRepo;
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

        public func getVerifyDocumentSourceUseCase() : VerifyDocumentSourceUseCase.VerifyDocumentSourceUseCase {
            VerifyDocumentSourceUseCase.VerifyDocumentSourceUseCase(
                documentRepo,
                getUpdateReputationUseCase(),
                reputationRepo,
                getCheckWhitelistUseCase(),
            );
        };

        private let verifierWhitelistRepo : VerifierWhitelistRepository.VerifierWhitelistRepository = VerifierWhitelistRepositoryImpl.VerifierWhitelistRepositoryImpl();

        public func getAddToWhitelistUseCase() : AddToWhitelistUseCase.AddToWhitelistUseCase {
            AddToWhitelistUseCase.AddToWhitelistUseCase(verifierWhitelistRepo);
        };

        public func getRemoveFromWhitelistUseCase() : RemoveFromWhitelistUseCase.RemoveFromWhitelistUseCase {
            RemoveFromWhitelistUseCase.RemoveFromWhitelistUseCase(verifierWhitelistRepo);
        };

        public func getCheckWhitelistUseCase() : CheckWhitelistUseCase.CheckWhitelistUseCase {
            CheckWhitelistUseCase.CheckWhitelistUseCase(verifierWhitelistRepo);
        };

        public func getGetWhitelistUseCase() : GetWhitelistUseCase.GetWhitelistUseCase {
            GetWhitelistUseCase.GetWhitelistUseCase(verifierWhitelistRepo);
        };

        public func getVerifierWhitelistRepository() : VerifierWhitelistRepository.VerifierWhitelistRepository {
            verifierWhitelistRepo;
        };
    };
};
