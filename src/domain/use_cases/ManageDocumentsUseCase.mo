import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import Result "mo:base/Result";

module {
    public class ManageDocumentsUseCase(documentRepo : DocumentRepository.DocumentRepository) {
        public func uploadDocument(doc : Document.Document) : async Result.Result<Int, Text> {
            await documentRepo.createDocument(doc);
        };

        public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
            await documentRepo.getDocument(id);
        };

        public func updateDocumentCategories(id : Document.DocumentId, newCategories : [Text], caller : Principal) : async Result.Result<(), Text> {
            let docResult = await documentRepo.getDocument(id);
            switch (docResult) {
                case (#ok(doc)) {
                    // if (doc.user != caller) {
                    //     return #err("Only the document owner can update categories");
                    // };
                    let updatedDoc = {
                        doc with
                        categories = newCategories;
                    };
                    let updateResult = await documentRepo.updateDocumentCategories(id, newCategories);
                    switch (updateResult) {
                        case (#ok(_)) { #ok(()) };
                        case (#err(e)) { #err(e) };
                    };
                };
                case (#err(e)) { #err(e) };
            };
        };

        public func updateDocument(doc : Document.Document) : async Result.Result<Nat, Text> {
            await documentRepo.updateDocument(doc);
        };

        public func deleteDocument(id : Document.DocumentId) : async Result.Result<(), Text> {
            await documentRepo.deleteDocument(id);
        };

        public func listUserDocuments(ownerId : Principal) : async Result.Result<[Document.Document], Text> {
            await documentRepo.listDocuments(ownerId);
        };

        public func getDocumentVersions(id : Document.DocumentId) : async Result.Result<[Document.Document], Text> {
            await documentRepo.getDocumentVersions(id);
        };

    };
};
