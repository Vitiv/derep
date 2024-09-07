import Document "../../domain/entities/Document";
import DocumentRepository "../../domain/repositories/DocumentRepository";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Time "mo:base/Time";
import ArrayUtils "../../../utils/ArrayUtils";
import T "../../domain/entities/Types";

module {
    public class DocumentRepositoryImpl() : DocumentRepository.DocumentRepository {
        public var documents = HashMap.HashMap<Document.DocumentId, Document.Document>(10, Nat.equal, Hash.hash);
        private var nextId : Nat = 0;

        public func createDocument(doc : Document.Document) : async Result.Result<Nat, Text> {
            let id = nextId;
            nextId += 1;
            let categories = if (doc.categories.size() == 0) {
                [T.DEFAULT_CATEGORY_CODE];
            } else {
                doc.categories;
            };
            let newDoc = {
                doc with id = id;
                previousVersion = null;
                categories = categories;
            };
            documents.put(id, newDoc);
            #ok(id);
        };

        public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
            switch (documents.get(id)) {
                case (?doc) {
                    #ok(doc);
                };
                case null {
                    #err("Document not found");
                };
            };
        };

        public func updateDocument(doc : Document.Document) : async Result.Result<Nat, Text> {
            Debug.print("DocumentRepositoryImpl: Updating document with ID: " # debug_show (doc.id));
            switch (documents.get(doc.id)) {
                case (?existingDoc) {
                    let newId = nextId;
                    nextId += 1;
                    let updatedDoc = {
                        doc with
                        id = newId;
                        previousVersion = ?existingDoc.id;
                    };
                    Debug.print("DocumentRepositoryImpl: Updating existing document : " # debug_show (updatedDoc));
                    documents.put(newId, updatedDoc);
                    #ok(newId);
                };
                case null {
                    #err("Original document not found");
                };
            };
        };

        public func updateDocumentCategories(id : Document.DocumentId, newCategories : [Text]) : async Result.Result<(), Text> {
            switch (documents.get(id)) {
                case (?doc) {
                    let updatedDoc = {
                        doc with
                        categories = newCategories;
                        updatedAt = Time.now();
                    };
                    documents.put(id, updatedDoc);
                    #ok(());
                };
                case (null) {
                    #err("Document not found");
                };
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

        public func getDocumentVersions(id : Document.DocumentId) : async Result.Result<[Document.Document], Text> {
            var versions : [Document.Document] = [];
            var currentId = ?id;
            while (currentId != null) {
                switch (documents.get(Option.unwrap(currentId))) {
                    case (?doc) {
                        versions := ArrayUtils.pushToArray(doc, versions);
                        currentId := doc.previousVersion;
                    };
                    case (null) {
                        return #err("Document version not found");
                    };
                };
            };
            #ok(versions);
        };

        public func verifyDocument(id : Document.DocumentId, review : Document.Review) : async Result.Result<(), Text> {
            Debug.print("DocumentRepositoryImpl: Verifying document with ID: " # debug_show (id));
            switch (documents.get(id)) {
                case (?doc) {
                    let updatedDoc = {
                        doc with
                        verifiedBy = ArrayUtils.pushToArray(review, doc.verifiedBy);
                    };
                    documents.put(id, updatedDoc);
                    #ok(());
                };
                case (null) {
                    #err("Document not found");
                };
            };
        };
    };
};
