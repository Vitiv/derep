import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

module {
    public class VerifyDocumentSourceUseCase(
        documentRepo : DocumentRepository.DocumentRepository,
        updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
    ) {
        public func execute(documentId : Document.DocumentId, reviewer : Text) : async Result.Result<(), Text> {
            Debug.print("VerifyDocumentSourceUseCase: Verifying document with ID: " # debug_show (documentId));
            let documentResult = await documentRepo.getDocument(documentId);
            switch (documentResult) {
                case (#ok(document)) {
                    Debug.print("VerifyDocumentSourceUseCase: Document found: " # debug_show (document));
                    // Check if the document has already been verified by this reviewer
                    let alreadyVerified = Array.find<Document.Review>(
                        document.verifiedBy,
                        func(review : Document.Review) : Bool {
                            Debug.print("Comparing reviewer: " # review.reviewer # " with " # reviewer);
                            review.reviewer == reviewer;
                        },
                    );

                    Debug.print("VerifyDocumentSourceUseCase: alreadyVerified: " # debug_show (alreadyVerified));

                    switch (alreadyVerified) {
                        case (?_) {
                            Debug.print("VerifyDocumentSourceUseCase: Document already verified by this reviewer");
                            return #err("Document already verified by this reviewer");
                        };
                        case (null) {
                            let sourceVerified = await verifySource(document.sourceUrl);
                            if (sourceVerified) {
                                let reputationResult = await updateReputationUseCase.assignFullReputation(document.user, document.contentType);
                                switch (reputationResult) {
                                    case (#ok(repValue)) {
                                        let newReview : Document.Review = {
                                            reviewer = reviewer;
                                            date = Time.now();
                                            reputation = repValue;
                                        };
                                        let verifyResult = await documentRepo.verifyDocument(documentId, newReview);
                                        switch (verifyResult) {
                                            case (#ok(_)) {
                                                Debug.print("VerifyDocumentSourceUseCase: Document verified successfully");
                                                #ok(());
                                            };
                                            case (#err(e)) {
                                                Debug.print("VerifyDocumentSourceUseCase: Failed to verify document: " # e);
                                                #err("Failed to verify document: " # e);
                                            };
                                        };
                                    };
                                    case (#err(e)) {
                                        Debug.print("VerifyDocumentSourceUseCase: Failed to assign reputation: " # e);
                                        #err("Failed to assign full reputation: " # e);
                                    };
                                };
                            } else {
                                Debug.print("VerifyDocumentSourceUseCase: Source verification failed");
                                #err("Source verification failed");
                            };
                        };
                    };
                };
                case (#err(e)) {
                    Debug.print("VerifyDocumentSourceUseCase: Failed to get document: " # e);
                    #err("Failed to get document: " # e);
                };
            };
        };

        private func verifySource(sourceUrl : ?Text) : async Bool {
            // Implement source verification logic here
            // This could involve checking against a whitelist of trusted sources,
            // making an HTTP request to validate the source, etc.
            // For now, we'll just return true if a sourceUrl is provided
            switch (sourceUrl) {
                case (null) { false };
                case (?_) { true };
            };
        };
    };
};
