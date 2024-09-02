import Time "mo:base/Time";
import Principal "mo:base/Principal";
import ReputationHistoryRepository "../repositories/ReputationHistoryRepository";
import ReputationHistoryTypes "../entities/ReputationHistoryTypes";

module {
    public class ReputationHistoryUseCase(reputationHistoryRepo : ReputationHistoryRepository.ReputationHistoryRepository) {
        public func addReputationChange(userId : Principal, categoryId : Text, value : Int) : async () {
            let change : ReputationHistoryTypes.ReputationChange = {
                userId = userId;
                categoryId = categoryId;
                value = value;
                timestamp = Time.now();
            };
            await reputationHistoryRepo.addReputationChange(change);
        };

        public func getReputationHistory(userId : Principal, categoryId : ?Text) : async [ReputationHistoryTypes.ReputationChange] {
            await reputationHistoryRepo.getReputationHistory(userId, categoryId);
        };
    };
};
