import Document "../../domain/entities/Document";
import DocumentRepository "../../domain/repositories/DocumentRepository";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";

module {
    public class DocumentRepositoryImpl() : DocumentRepository.DocumentRepository {
        public var documents = HashMap.HashMap<Document.DocumentId, Document.Document>(10, Nat.equal, Hash.hash);
        private var nextId : Nat = 0;

        public func createDocument(doc : Document.Document) : async Result.Result<(), Text> {
            let id = nextId;
            nextId += 1;
            let newDoc = { doc with id = id };
            documents.put(id, newDoc);
            #ok;
        };

        public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
            switch (documents.get(id)) {
                case (?doc) { #ok(doc) };
                case null { #err("Document not found") };
            };
        };

        public func updateDocument(doc : Document.Document) : async Result.Result<(), Text> {
            switch (documents.get(doc.id)) {
                case (?_) {
                    documents.put(doc.id, doc);
                    #ok(());
                };
                case null { #err("Document not found") };
            };
        };

        public func deleteDocument(id : Document.DocumentId) : async Result.Result<(), Text> {
            switch (documents.remove(id)) {
                case (?_) { #ok(()) };
                case null { #err("Document not found") };
            };
        };

        public func listDocuments(user : Principal) : async Result.Result<[Document.Document], Text> {
            let userDocs = Iter.toArray(Iter.filter(documents.vals(), func(doc : Document.Document) : Bool { doc.user == user }));
            #ok(userDocs);
        };
    };
};
