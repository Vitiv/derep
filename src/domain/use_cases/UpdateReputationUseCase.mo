import Result "mo:base/Result";
import User "../entities/User";
import Category "../entities/Category";
import Reputation "../entities/Reputation";
import ReputationRepository "../repositories/ReputationRepository";
import UserRepository "../repositories/UserRepository";
import ReputationHistoryUseCase "./ReputationHistoryUseCase";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class UpdateReputationUseCase(
        reputationRepo : ReputationRepository.ReputationRepository,
        userRepo : UserRepository.UserRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
        reputationHistoryUseCase : ReputationHistoryUseCase.ReputationHistoryUseCase,
    ) {
        public func execute(userId : User.UserId, categoryId : Category.CategoryId, value : Int) : async Result.Result<Int, Text> {
            await categoryRepo.ensureCategoryHierarchy(categoryId);
            // Validate user existence
            switch (await userRepo.getUser(userId)) {
                case null { return #err("User not found") };
                case (?_) {};
            };

            // Update reputation
            switch (await reputationRepo.getReputation(userId, categoryId)) {
                case (?reputation) {
                    let newScore = reputation.score + value;
                    let updatedReputation = Reputation.updateScore(reputation, newScore);
                    if (await reputationRepo.updateReputation(updatedReputation)) {
                        await reputationHistoryUseCase.addReputationChange(userId, categoryId, value);
                        #ok(newScore);
                    } else {
                        #err("Failed to update reputation");
                    };
                };
                case (null) {
                    let newReputation = Reputation.createReputation(userId, categoryId);
                    let initializedReputation = Reputation.updateScore(newReputation, value);
                    if (await reputationRepo.updateReputation(initializedReputation)) {
                        await reputationHistoryUseCase.addReputationChange(userId, categoryId, value);
                        #ok(newReputation.score);
                    } else {
                        #err("Failed to create new reputation");
                    };
                };
            };
        };

        public func assignTemporaryReputation(userId : User.UserId, contentType : Text) : async Result.Result<Int, Text> {
            let tempValue = 1; // Define a small temporary reputation value
            let category = await determineCategoryFromContentType(contentType);
            await execute(userId, category, tempValue);
        };

        public func assignFullReputation(userId : User.UserId, contentType : Text) : async Result.Result<Int, Text> {
            let fullValue = 10; // Define the full reputation value
            let category = await determineCategoryFromContentType(contentType);
            await execute(userId, category, fullValue);
        };

        private func determineCategoryFromContentType(contentType : Text) : async Category.CategoryId {
            // Implement logic to determine category based on content type
            // For now, we'll just return a default category
            "1.2.2" // Internet Computer category
        };

    };
};
