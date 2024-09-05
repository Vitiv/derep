import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import Result "mo:base/Result";

module {
    public class ManageDocumentsUseCase(documentRepo : DocumentRepository.DocumentRepository) {
        public func uploadDocument(doc : Document.Document) : async Result.Result<(), Text> {
            await documentRepo.createDocument(doc);
        };

        public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
            await documentRepo.getDocument(id);
        };

        public func updateDocument(doc : Document.Document) : async Result.Result<(), Text> {
            await documentRepo.updateDocument(doc);
        };

        public func deleteDocument(id : Document.DocumentId) : async Result.Result<(), Text> {
            await documentRepo.deleteDocument(id);
        };

        public func listUserDocuments(ownerId : Principal) : async Result.Result<[Document.Document], Text> {
            await documentRepo.listDocuments(ownerId);
        };
    };
};
