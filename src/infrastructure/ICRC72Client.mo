import Principal "mo:base/Principal";
import Result "mo:base/Result";
import T "../domain/entities/Types";

module {
    type Event = T.Event;
    type EventNotification = T.EventNotification;
    type BroadcasterActor = actor {
        subscribe : (Principal, Text, [Text]) -> async Bool;
        icrc72_publish : ([Event]) -> async Result.Result<Nat, Text>;
    };

    public class ICRC72ClientImpl(hubPrincipal : Principal, caller : Principal) {
        public func subscribe(namespace : Text) : async Bool {
            let broadcaster : BroadcasterActor = actor (Principal.toText(hubPrincipal));
            await broadcaster.subscribe(caller, namespace, [namespace]);
        };

        public func publish(event : T.Event) : async Result.Result<Nat, Text> {
            let broadcaster : BroadcasterActor = actor (Principal.toText(hubPrincipal));
            await broadcaster.icrc72_publish([event]);
        };
    };
};
