import IncomingFile "../entities/IncomingFile";
import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import SHA256 "mo:sha2/Sha256";
import UserRepository "../repositories/UserRepository";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class ProcessIncomingFileUseCase(
        documentRepo : DocumentRepository.DocumentRepository,
        updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
        userRepo : UserRepository.UserRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
    ) {
        public func execute(file : IncomingFile.IncomingFile, caller : Principal) : async Result.Result<Document.DocumentId, Text> {
            // Check if user exists
            Debug.print("ProcessIncomingFileUseCase: Checking user existence for " # Principal.toText(caller));
            let userExists = await userRepo.getUser(caller);
            switch (userExists) {
                case (null) {
                    Debug.print("ProcessIncomingFileUseCase: User not found for " # Principal.toText(caller));
                    return #err("User not found. Please register before uploading documents.");
                };
                case (?user) {
                    Debug.print("ProcessIncomingFileUseCase: User found: " # debug_show (user));
                };
            };

            let now = Time.now();
            let size = Blob.toArray(file.content).size();
            let hash = SHA256.fromBlob(#sha256, file.content);
            // Debug.print("ProcessIncomingFileUseCase: hash: " # debug_show (hash));
            let hashText = bytesToHex(Blob.toArray(hash));
            // Debug.print("ProcessIncomingFileUseCase: hashText: " # debug_show (hashText));

            // Validate categories
            for (categoryId in file.categories.vals()) {
                let categoryExists = await categoryRepo.getCategory(categoryId);
                if (categoryExists == null) {
                    return #err("Invalid category: " # categoryId);
                };
            };

            let document : Document.Document = {
                id = 0; // This will be set by the repository
                name = file.name;
                content = file.content;
                contentType = file.contentType;
                size = size;
                hash = hashText;
                source = Principal.toText(caller);
                sourceUrl = file.sourceUrl;
                user = caller;
                createdAt = now;
                updatedAt = now;
                verifiedBy = []; // Initially empty
                previousVersion = null;
                categories = file.categories;
            };

            Debug.print("ProcessIncomingFileUseCase: Creating document");
            let result = await documentRepo.createDocument(document);
            switch (result) {
                case (#ok(docId)) {
                    // Assign temporary reputation
                    Debug.print("ProcessIncomingFileUseCase: Document created with ID: " # debug_show (docId));
                    let tempReputationResult = await updateReputationUseCase.assignTemporaryReputation(caller, document.contentType);
                    switch (tempReputationResult) {
                        case (#ok(tempRepValue)) {
                            Debug.print("ProcessIncomingFileUseCase: Temporary reputation assigned: " # debug_show (tempRepValue));
                            let review : Document.Review = {
                                reviewer = "aaaaa-aa"; // TODO change to canister id
                                date = now;
                                reputation = tempRepValue;
                            };
                            ignore await documentRepo.verifyDocument(docId, review);
                            #ok(docId);
                        };
                        case (#err(e)) {
                            Debug.print("ProcessIncomingFileUseCase: Failed to assign temporary reputation: " # debug_show (e));
                            #err("Document created but failed to assign temporary reputation: " # e);
                        };
                    };
                };
                case (#err(e)) {
                    Debug.print("ProcessIncomingFileUseCase: Failed to create document: " # debug_show (e));
                    #err(e);
                };
            };
        };

        func bytesToHex(bytes : [Nat8]) : Text {
            let hexChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
            var result = "";
            for (byte in bytes.vals()) {
                result #= hexChars[Nat8.toNat(byte / 16)];
                result #= hexChars[Nat8.toNat(byte % 16)];
            };
            result;
        };
    };
};
