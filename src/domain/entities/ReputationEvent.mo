import User "./User";
import Category "./Category";
import Time "mo:base/Time";

module {
    public type EventId = Nat;

    public type ReputationEvent = {
        id : EventId;
        userId : User.UserId;
        categoryId : Category.CategoryId;
        score : Int;
        timestamp : Int;
        namespace : Text;
        metadata : [(Text, Text)];
    };

    public func createEvent(
        id : EventId,
        userId : User.UserId,
        categoryId : Category.CategoryId,
        score : Int,
        namespace : Text,
        metadata : [(Text, Text)],
    ) : ReputationEvent {
        {
            id = id;
            userId = userId;
            categoryId = categoryId;
            score = score;
            timestamp = Time.now();
            namespace = namespace;
            metadata = metadata;
        };
    };
};
