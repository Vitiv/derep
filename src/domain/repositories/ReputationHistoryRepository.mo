import ReputationHistoryTypes "../entities/ReputationHistoryTypes";
import HashMap "mo:base/HashMap";

module {
    public type ReputationHistoryRepository = {
        var history : HashMap.HashMap<Principal, [ReputationHistoryTypes.ReputationChange]>;
        addReputationChange : (ReputationHistoryTypes.ReputationChange) -> async ();
        getReputationHistory : (Principal, ?Text) -> async [ReputationHistoryTypes.ReputationChange];
    };
};
