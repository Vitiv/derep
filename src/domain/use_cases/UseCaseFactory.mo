import UserRepositoryImpl "../../data/repositories/UserRepositoryImpl";
import ReputationRepositoryImpl "../../data/repositories/ReputationRepositoryImpl";
import CategoryRepositoryImpl "../../data/repositories/CategoryRepositoryImpl";
import ManageCategories "./ManageCategories";
import UpdateReputation "./UpdateReputationUseCase";
import GetUserReputation "./GetUserReputation";
import HandleNotificationUseCase "./HandleNotificationUseCase";
import PublishEventUseCase "./PublishEventUseCase";
import DeleteUserUseCase "./DeleteUserUseCase";
import DeleteCategoryUseCase "./DeleteCategoryUseCase";
import ClearAllDataUseCase "./ClearAllDataUseCase";
import ICRC72Client "../../infrastructure/ICRC72Client";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import NotificationRepositoryImpl "../../data/repositories/NotificationRepositoryImpl";
import NotificationUseCase "./NotificationUseCase";

module {
    public class UseCaseFactory(
        userRepo : UserRepositoryImpl.UserRepositoryImpl,
        reputationRepo : ReputationRepositoryImpl.ReputationRepositoryImpl,
        categoryRepo : CategoryRepositoryImpl.CategoryRepositoryImpl,
        notificationRepo : NotificationRepositoryImpl.NotificationRepositoryImpl,
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
