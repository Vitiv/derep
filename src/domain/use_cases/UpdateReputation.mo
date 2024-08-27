import Reputation "../entities/Reputation";
import User "../entities/User";
import ReputationRepository "../repositories/ReputationRepository";
import Result "mo:base/Result";
import Int "mo:base/Int";

module {
    public class UpdateReputationUseCase(reputationRepo : ReputationRepository.ReputationRepository) {
        public func execute(userId : User.UserId, categoryId : Reputation.CategoryId, scoreChange : Int) : async Result.Result<(), Text> {
            switch (await reputationRepo.getReputation(userId, categoryId)) {
                case (?reputation) {
                    let newScore = calculateNewScore(reputation.score, scoreChange);
                    let updatedReputation = Reputation.updateScore(reputation, newScore);
                    if (await reputationRepo.updateReputation(updatedReputation)) {
                        #ok(());
                    } else {
                        #err("Failed to update reputation");
                    };
                };
                case (null) {
                    let newReputation = Reputation.createReputation(userId, categoryId);
                    let initializedReputation = Reputation.updateScore(newReputation, scoreChange);
                    if (await reputationRepo.updateReputation(initializedReputation)) {
                        #ok(());
                    } else {
                        #err("Failed to create new reputation");
                    };
                };
            };
        };

        private func calculateNewScore(currentScore : Reputation.ReputationScore, change : Int) : Reputation.ReputationScore {
            Int.max(0, currentScore + change); // Ensure score doesn't go below 0
        };
    };
};
