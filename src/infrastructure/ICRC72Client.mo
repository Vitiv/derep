import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import T "../domain/entities/Types";

module {
    type Event = T.Event;
    type EventNotification = T.EventNotification;
    type SubscriptionInfo = T.SubscriptionInfo;
    public type PublishResult = [{
        Ok : [Nat];
        Err : [PublishError];
    }];

    public type PublishError = {
        #GenericError : { message : Text; error_code : Nat };
        #Busy;
        #ImproperId : Text;
        #Unauthorized;
    };

    type BroadcasterActor = actor {
        subscribe : (SubscriptionInfo) -> async Bool;
        icrc72_publish : ([Event]) -> async PublishResult;
    };

    public class ICRC72ClientImpl(hubPrincipal : Principal, caller : Principal) {
        public func subscribe(namespace : Text) : async Bool {
            let broadcaster : BroadcasterActor = actor (Principal.toText(hubPrincipal));
            let sub_args : T.SubscriptionInfo = {
                namespace = namespace;
                subscriber = caller;
                active = true;
                filters = [namespace];
                messagesReceived = 0;
                messagesRequested = 0;
                messagesConfirmed = 0;
            };
            await broadcaster.subscribe(sub_args);
        };

        public func publish(event : Event) : async Result.Result<[Nat], Text> {
            let broadcaster : BroadcasterActor = actor (Principal.toText(hubPrincipal));
            let publishResult = await broadcaster.icrc72_publish([{
                id = event.id;
                prevId = null;
                timestamp = event.timestamp;
                namespace = event.namespace;
                data = event.data;
                source = event.source;
                headers = null;
            }]);
            Debug.print("ICRC72ClientImpl.publish: response " # debug_show (publishResult));
            if (publishResult.size() > 0) {
                if (publishResult[0].Ok.size() > 0) {
                    return #ok(publishResult[0].Ok);
                } else {
                    let errorMessage = switch (publishResult[0].Err[0]) {
                        case (#GenericError(e)) { e.message };
                        case (#Busy) { "Broadcaster is busy" };
                        case (#ImproperId(id)) { "Improper ID: " # id };
                        case (#Unauthorized) { "Unauthorized" };
                    };
                    return #err(errorMessage);
                };
            };
            #err("No response");
        };
    };
};
