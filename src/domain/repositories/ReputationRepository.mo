import Reputation "../entities/Reputation";
import User "../entities/User";
import Category "../entities/Category";
import HashMap "mo:base/HashMap";

module {
    public type ReputationRepository = {
        var reputations : HashMap.HashMap<(User.UserId, Category.CategoryId), Reputation.Reputation>;

        keyEqual : ((User.UserId, Category.CategoryId), (User.UserId, Category.CategoryId)) -> Bool;
        keyHash : ((User.UserId, Category.CategoryId)) -> Nat32;
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
