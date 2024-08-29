import T "../entities/Types";
import ICRC72Client "../../infrastructure/ICRC72Client";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Option "mo:base/Option";

module {
    public class PublishEventUseCase(icrc72Client : ICRC72Client.ICRC72ClientImpl) {
        public func publishReputationIncreaseEvent(data : T.ReputationUpdateInfo, source : Principal) : async () {
            let event : T.Event = {
                id = 1;
                prevId = null;
                timestamp = Int.abs(Time.now());
                namespace = T.INCREASE_REPUTATION_NAMESPACE;
                headers = null;
                data = #Map([
                    ("user", #Principal(data.user)),
                    ("category", #Text(Option.get(data.category, T.DEFAULT_CATEGORY))),
                    ("value", #Int(data.value)),
                ]);
                source = source;
            };

            let result = await icrc72Client.publish(event);
            switch (result) {
                case (#ok(_)) {
                    Debug.print("Published reputation increase event");
                };
                case (#err(error)) {
                    Debug.print("Failed to publish event: " # error);
                };
            };
        };
    };
};
