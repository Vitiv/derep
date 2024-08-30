import User "../entities/User";
import UserRepository "../repositories/UserRepository";
import ReputationRepository "../repositories/ReputationRepository";

module {
    public class DeleteUserUseCase(userRepo : UserRepository.UserRepository, reputationRepo : ReputationRepository.ReputationRepository) {
        public func execute(userId : User.UserId) : async Bool {
            let repDeleted = await reputationRepo.deleteUserReputations(userId);
            let userDeleted = await userRepo.deleteUser(userId);
            repDeleted and userDeleted;
        };
    };
};
