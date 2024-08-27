import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

import ICRC72Client "../src/infrastructure/ICRC72Client";
import T "../src/domain/entities/Types";

actor class TestCanister(reputationActorPrincipal : Principal) = Self {
    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;

    let increaseReputationNamespace : Namespace = "increase.reputation.ava";
    let updateReputationNamespace : Namespace = "update.reputation.ava";

    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;

    public shared func initialize(hubPrincipal : Principal) : async () {
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(hubPrincipal, Principal.fromActor(Self));

        switch (icrc72Client) {
            case (?client) {
                ignore await client.subscribe(increaseReputationNamespace);
                Debug.print("TestCanister: Subscribed to " # increaseReputationNamespace);
            };
            case (null) {
                Debug.print("TestCanister: ICRC72 client not initialized");
            };
        };
    };

    public shared func publishReputationUpdateEvent(
        userId : Text,
        categoryId : Text,
        scoreChange : Int,
        verificationCanister : Principal,
        verificationMethod : Text,
    ) : async () {
        let event : EventNotification = {
            id = 1;
            eventId = 111;
            prevId = null;
            timestamp = 1629123456000000000;
            namespace = updateReputationNamespace;
            headers = null;
            filter = null;
            data = #Map([
                ("user", #Principal(Principal.fromText(userId))),
                ("category", #Text(categoryId)),
                ("value", #Int(scoreChange)),
                ("verificationCanister", #Principal(verificationCanister)),
                ("verificationMethod", #Text(verificationMethod)),
                ("documentId", #Nat(12345)),
            ]);
            source = Principal.fromActor(Self);
        };

        switch (icrc72Client) {
            case (?client) {
                let result = await client.publish(event);
                switch (result) {
                    case (#ok(ids)) {
                        Debug.print("TestCanister: Published reputation update event with IDs: " # debug_show (ids));
                    };
                    case (#err(error)) {
                        Debug.print("TestCanister: Failed to publish event: " # error);
                    };
                };
            };
            case (null) {
                Debug.print("TestCanister: ICRC72 client not initialized, couldn't publish event");
            };
        };
    };

    public func icrc72_handle_notification(notifications : [EventNotification]) : async () {
        Debug.print("TestCanister: Notifications received: " # Nat.toText(notifications.size()));
        for (notification in notifications.vals()) {
            Debug.print("TestCanister: Received event: " # debug_show (notification));
        };
    };
};
