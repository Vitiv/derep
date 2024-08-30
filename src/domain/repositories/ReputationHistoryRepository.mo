import ReputationHistoryTypes "../entities/ReputationHistoryTypes";

module {
    public type ReputationHistoryRepository = {
        addReputationChange : (ReputationHistoryTypes.ReputationChange) -> async ();
        getReputationHistory : (Principal, ?Text) -> async [ReputationHistoryTypes.ReputationChange];
    };
};
