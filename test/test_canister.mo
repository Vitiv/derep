import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Error "mo:base/Error";

import ICRC72Client "../src/infrastructure/ICRC72Client";
import T "../src/domain/entities/Types";
import Document "../src/domain/entities/Document";
import IncomingFile "../src/domain/entities/IncomingFile";

actor class TestCanister() = Self {
    type ReputationActor = actor {
        uploadDocument : (IncomingFile.IncomingFile) -> async Result.Result<Document.DocumentId, Text>;
        verifyDocumentSource : (Document.DocumentId, ?Principal) -> async Result.Result<(), Text>;
    };

    let reputationActorId : Text = "be2us-64aaa-aaaaa-qaabq-cai";
    let reputationActor : ReputationActor = actor (reputationActorId);

    public shared func createTestDocument(userId : Principal, content : Text, category : [Text]) : async Result.Result<Document.DocumentId, Text> {
        Debug.print("TestCanister: Creating test document for user " # Principal.toText(userId));

        let testDocument : IncomingFile.IncomingFile = {
            name = "test_document.txt";
            content = Text.encodeUtf8(content);
            contentType = "text/plain";
            user = Principal.toText(userId);
            sourceUrl = ?"https://example.com/test";
            categories = category;
        };

        try {
            let result = await reputationActor.uploadDocument(testDocument);
            Debug.print("TestCanister: Document upload result: " # debug_show (result));
            result;
        } catch (error) {
            Debug.print("TestCanister: Error uploading document: " # Error.message(error));
            #err("Failed to upload document: " # Error.message(error));
        };
    };

    type Namespace = T.Namespace;
    type EventNotification = T.EventNotification;

    let increaseReputationNamespace : Namespace = T.INCREASE_REPUTATION_NAMESPACE;
    let updateReputationNamespace : Namespace = T.UPDATE_REPUTATION_NAMESPACE;

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

    public shared func verifyDocumentSource(documentId : Document.DocumentId, reviewer : ?Principal) : async Result.Result<(), Text> {
        Debug.print("TestCanister: Verifying document with ID: " # debug_show (documentId));

        try {
            let result = await reputationActor.verifyDocumentSource(documentId, reviewer);
            Debug.print("TestCanister: Document verification result: " # debug_show (result));
            result;
        } catch (error) {
            Debug.print("TestCanister: Error verifying document: " # Error.message(error));
            #err("Failed to verify document: " # Error.message(error));
        };
    };
};
