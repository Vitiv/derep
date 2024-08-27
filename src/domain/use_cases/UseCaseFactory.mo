import UserRepository "../repositories/UserRepository";
import ReputationRepository "../repositories/ReputationRepository";
import CategoryRepository "../repositories/CategoryRepository";
import ManageCategories "./ManageCategories";
import UpdateReputation "./UpdateReputation";
import GetUserReputation "./GetUserReputation";
//import RegisterUser "./RegisterUser";
//import GetUser "./GetUser";
import HandleReputationEvent "./HandleReputationEvent";

module {
    public class UseCaseFactory(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
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

        //  public func getRegisterUserUseCase() : RegisterUser.RegisterUserUseCase {
        //      RegisterUser.RegisterUserUseCase(userRepo)
        //  };

        //  public func getGetUserUseCase() : GetUser.GetUserUseCase {
        //      GetUser.GetUserUseCase(userRepo)
        //  };

        public func getHandleReputationEventUseCase() : HandleReputationEvent.HandleReputationEventUseCase {
            HandleReputationEvent.HandleReputationEventUseCase(reputationRepo, categoryRepo);
        };
    };
};
