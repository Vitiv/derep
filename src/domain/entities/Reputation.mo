import User "./User";
import Time "mo:base/Time";

module {
    public type CategoryId = Text;
    public type ReputationScore = Int;

    public type Reputation = {
        userId : User.UserId;
        categoryId : CategoryId;
        score : ReputationScore;
        lastUpdated : Int;
    };

    public func createReputation(userId : User.UserId, categoryId : CategoryId) : Reputation {
        {
            userId = userId;
            categoryId = categoryId;
            score = 0;
            lastUpdated = Time.now();
        };
    };

    public func updateScore(reputation : Reputation, newScore : ReputationScore) : Reputation {
        {
            userId = reputation.userId;
            categoryId = reputation.categoryId;
            score = newScore;
            lastUpdated = Time.now();
        };
    };
};
