import ICRC72Client "../../infrastructure/ICRC72Client";
import CategoryRepository "../repositories/CategoryRepository";
import NotificationRepository "../repositories/NotificationRepository";
import ReputationRepository "../repositories/ReputationRepository";
import UserRepository "../repositories/UserRepository";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import ClearAllDataUseCase "./ClearAllDataUseCase";
import DeleteCategoryUseCase "./DeleteCategoryUseCase";
import DeleteUserUseCase "./DeleteUserUseCase";
import GetUserReputation "./GetUserReputation";
import HandleNotificationUseCase "./HandleNotificationUseCase";
import ManageCategories "./ManageCategories";
import NotificationUseCase "./NotificationUseCase";
import PublishEventUseCase "./PublishEventUseCase";
import UpdateReputation "./UpdateReputationUseCase";

module {
    public class UseCaseFactory(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
        notificationRepo : NotificationRepository.NotificationRepository,
        icrc72Client : ICRC72Client.ICRC72ClientImpl,
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
    ) {
        public func getManageCategoriesUseCase() : ManageCategories.ManageCategoriesUseCase {
            ManageCategories.ManageCategoriesUseCase(categoryRepo);
        };

        public func getUpdateReputationUseCase() : UpdateReputation.UpdateReputationUseCase {
            UpdateReputation.UpdateReputationUseCase(reputationRepo, userRepo);
        };

        public func getGetUserReputationUseCase() : GetUserReputation.GetUserReputationUseCase {
            GetUserReputation.GetUserReputationUseCase(reputationRepo);
        };

        public func getHandleNotificationUseCase() : HandleNotificationUseCase.HandleNotificationUseCase {
            HandleNotificationUseCase.HandleNotificationUseCase(
                namespaceCategoryMapper,
                getUpdateReputationUseCase(),
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
    };
};
