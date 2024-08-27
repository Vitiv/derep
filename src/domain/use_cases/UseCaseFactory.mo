import UserRepositoryImpl "../../data/repositories/UserRepositoryImpl";
import ReputationRepositoryImpl "../../data/repositories/ReputationRepositoryImpl";
import CategoryRepositoryImpl "../../data/repositories/CategoryRepositoryImpl";
import ManageCategories "./ManageCategories";
import UpdateReputation "./UpdateReputation";
import GetUserReputation "./GetUserReputation";
import HandleReputationEvent "./HandleReputationEvent";

module {
    public class UseCaseFactory(
        userRepo : UserRepositoryImpl.UserRepositoryImpl,
        reputationRepo : ReputationRepositoryImpl.ReputationRepositoryImpl,
        categoryRepo : CategoryRepositoryImpl.CategoryRepositoryImpl,
    ) {
        public func getManageCategoriesUseCase() : ManageCategories.ManageCategoriesUseCase {
            ManageCategories.ManageCategoriesUseCase(categoryRepo);
        };

        public func getUpdateReputationUseCase() : UpdateReputation.UpdateReputationUseCase {
            UpdateReputation.UpdateReputationUseCase(reputationRepo);
        };

        public func getGetUserReputationUseCase() : GetUserReputation.GetUserReputationUseCase {
            GetUserReputation.GetUserReputationUseCase(reputationRepo);
        };

        public func getHandleReputationEventUseCase() : HandleReputationEvent.HandleReputationEventUseCase {
            HandleReputationEvent.HandleReputationEventUseCase(reputationRepo, categoryRepo);
        };
    };
};
