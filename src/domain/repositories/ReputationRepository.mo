import Reputation "../entities/Reputation";
import User "../entities/User";
import Category "../entities/Category";

module {
    public type ReputationRepository = {
        getReputation : (User.UserId, Category.CategoryId) -> async ?Reputation.Reputation;
        updateReputation : (Reputation.Reputation) -> async Bool;
        getUserReputations : (User.UserId) -> async [Reputation.Reputation];
        getCategoryReputations : (Category.CategoryId) -> async [Reputation.Reputation];
        getAllReputations : () -> async [Reputation.Reputation];
        getTopUsersByCategoryId : (Category.CategoryId, Nat) -> async [(User.UserId, Int)];
        getTotalUserReputation : (User.UserId) -> async Int;
        deleteUserReputations : (User.UserId) -> async Bool;
        deleteCategoryReputations : (Category.CategoryId) -> async Bool;
        clearAllReputations : () -> async Bool;
    };
};
