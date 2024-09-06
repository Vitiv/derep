import IncomingFile "../entities/IncomingFile";
import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import SHA256 "mo:sha2/Sha256";

module {
    public class ProcessIncomingFileUseCase(documentRepo : DocumentRepository.DocumentRepository) {
        public func execute(file : IncomingFile.IncomingFile, caller : Principal) : async Result.Result<Document.DocumentId, Text> {
            let now = Time.now();
            let size = Blob.toArray(file.content).size();
            let hash = SHA256.fromBlob(#sha256, file.content);
            let decoded_text : Text = switch (Text.decodeUtf8(hash)) {
                case (null) { "No value returned" };
                case (?y) { y };
            };

            let document : Document.Document = {
                id = 0; // This will be set by the repository
                name = file.name;
                content = file.content;
                contentType = file.contentType;
                size = size;
                hash = decoded_text;
                source = Principal.toText(caller);
                user = caller;
                createdAt = now;
                updatedAt = now;
            };

            let result = await documentRepo.createDocument(document);
            switch (result) {
                case (#ok()) { #ok(document.id) };
                case (#err(e)) { #err(e) };
            };
        };
    };
};
