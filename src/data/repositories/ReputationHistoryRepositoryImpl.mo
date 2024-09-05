import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import ReputationHistoryTypes "../../domain/entities/ReputationHistoryTypes";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class ReputationHistoryRepositoryImpl() {
        public var history = HashMap.HashMap<Principal, [ReputationHistoryTypes.ReputationChange]>(10, Principal.equal, Principal.hash);

        public func addReputationChange(change : ReputationHistoryTypes.ReputationChange) : async () {
            let userHistory = switch (history.get(change.userId)) {
                case null [];
                case (?h) h;
            };
            let updatedHistory = ArrayUtils.pushToArray(change, userHistory);
            history.put(change.userId, updatedHistory);
        };

        public func getReputationHistory(userId : Principal, categoryId : ?Text) : async [ReputationHistoryTypes.ReputationChange] {
            switch (history.get(userId)) {
                case null [];
                case (?userHistory) {
                    switch (categoryId) {
                        case null userHistory;
                        case (?cid) Array.filter(
                            userHistory,
                            func(change : ReputationHistoryTypes.ReputationChange) : Bool {
                                change.categoryId == cid;
                            },
                        );
                    };
                };
            };
        };
    };
};
