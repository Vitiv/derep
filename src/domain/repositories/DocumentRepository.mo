import Document "../entities/Document";
import Result "mo:base/Result";

module {
    public type DocumentRepository = {
        createDocument : (Document.Document) -> async Result.Result<(), Text>;
        getDocument : (Document.DocumentId) -> async Result.Result<Document.Document, Text>;
        updateDocument : (Document.Document) -> async Result.Result<(), Text>;
        deleteDocument : (Document.DocumentId) -> async Result.Result<(), Text>;
        listDocuments : (Principal) -> async Result.Result<[Document.Document], Text>;
    };
};
