import Reputation "../entities/Reputation";
import User "../entities/User";
import ReputationRepositoryImpl "../../data/repositories/ReputationRepositoryImpl";
import Result "mo:base/Result";
import Int "mo:base/Int";

module {
    public class UpdateReputationUseCase(reputationRepo : ReputationRepositoryImpl.ReputationRepositoryImpl) {
        public func execute(userId : User.UserId, categoryId : Reputation.CategoryId, scoreChange : Int) : Result.Result<(), Text> {
            switch (reputationRepo.getReputation(userId, categoryId)) {
                case (?reputation) {
                    let newScore = calculateNewScore(reputation.score, scoreChange);
                    let updatedReputation = Reputation.updateScore(reputation, newScore);
                    if (reputationRepo.updateReputation(updatedReputation)) {
                        #ok(());
                    } else {
                        #err("Failed to update reputation");
                    };
                };
                case (null) {
                    let newReputation = Reputation.createReputation(userId, categoryId);
                    let initializedReputation = Reputation.updateScore(newReputation, scoreChange);
                    if (reputationRepo.updateReputation(initializedReputation)) {
                        #ok(());
                    } else {
                        #err("Failed to create new reputation");
                    };
                };
            };
        };

        private func calculateNewScore(currentScore : Reputation.ReputationScore, change : Int) : Reputation.ReputationScore {
            currentScore + change; // Allow negative scores
        };
    };
};
