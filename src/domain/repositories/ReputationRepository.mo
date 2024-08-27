import Reputation "../entities/Reputation";
import User "../entities/User";
import Category "../entities/Category";

module {
    public type ReputationRepository = actor {
        getReputation : query (User.UserId, Category.CategoryId) -> async ?Reputation.Reputation;
        updateReputation : (Reputation.Reputation) -> async Bool;
        getUserReputations : query (User.UserId) -> async [Reputation.Reputation];
        getCategoryReputations : query (Category.CategoryId) -> async [Reputation.Reputation];
    };
};
