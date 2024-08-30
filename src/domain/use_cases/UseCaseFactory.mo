import ICRC72Client "../../infrastructure/ICRC72Client";
import ReputationHistoryTypes "../entities/ReputationHistoryTypes";
import CategoryRepository "../repositories/CategoryRepository";
import NotificationRepository "../repositories/NotificationRepository";
import ReputationRepository "../repositories/ReputationRepository";
import UserRepository "../repositories/UserRepository";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import ClearAllDataUseCase "./ClearAllDataUseCase";
import DeleteCategoryUseCase "./DeleteCategoryUseCase";
import DeleteUserUseCase "./DeleteUserUseCase";
import GetUserReputation "./GetUserReputation";
import HandleReputationEventUseCase "./HandleReputationEventUseCase";
import ManageCategories "./ManageCategoriesUseCase";
import NotificationUseCase "./NotificationUseCase";
import PublishEventUseCase "./PublishEventUseCase";
import ReputationHistoryUseCase "./ReputationHistoryUseCase";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import ReputationHistoryRepository "../repositories/ReputationHistoryRepository";
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

        // public func getHandleReputationEventUseCase() : HandleReputationEventUseCase.HandleReputationEventUseCase {
        //     HandleReputationEventUseCase.HandleReputationEventUseCase(
        //         categoryRepo,
        //         getUpdateReputationUseCase(),
        //
        //     );
        // };

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
