import Reputation "../entities/Reputation";
import User "../entities/User";
import ReputationRepositoryImpl "../../data/repositories/ReputationRepositoryImpl";
import Result "mo:base/Result";

module {
    public class GetUserReputationUseCase(reputationRepo : ReputationRepositoryImpl.ReputationRepositoryImpl) {
        public func execute(userId : User.UserId, categoryId : Reputation.CategoryId) : async Result.Result<Reputation.Reputation, Text> {
            switch (await reputationRepo.getReputation(userId, categoryId)) {
                case (?reputation) { #ok(reputation) };
                case (null) { #err("Reputation not found") };
            };
        };

        public func getUserReputations(userId : User.UserId) : async Result.Result<[Reputation.Reputation], Text> {
            #ok(await reputationRepo.getUserReputations(userId));
        };
    };
};
