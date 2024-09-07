import Document "../entities/Document";
import Result "mo:base/Result";

module {
    public type DocumentRepository = {
        createDocument : (Document.Document) -> async Result.Result<Nat, Text>;
        getDocument : (Document.DocumentId) -> async Result.Result<Document.Document, Text>;
        updateDocument : (Document.Document) -> async Result.Result<Nat, Text>;
        verifyDocument : (Document.DocumentId, Document.Review) -> async Result.Result<(), Text>;
        deleteDocument : (Document.DocumentId) -> async Result.Result<(), Text>;
        listDocuments : (Principal) -> async Result.Result<[Document.Document], Text>;
        getDocumentVersions : (Document.DocumentId) -> async Result.Result<[Document.Document], Text>;
    };
};
