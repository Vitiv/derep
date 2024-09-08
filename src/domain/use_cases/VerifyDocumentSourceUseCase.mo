import Document "../entities/Document";
import DocumentRepository "../repositories/DocumentRepository";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import ReputationRepository "../repositories/ReputationRepository";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import T "../../domain/entities/Types";
import CheckWhitelistUseCase "./CheckWhitelistUseCase";

module {
    public class VerifyDocumentSourceUseCase(
        documentRepo : DocumentRepository.DocumentRepository,
        updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
        reputationRepo : ReputationRepository.ReputationRepository,
        checkWhitelistUseCase : CheckWhitelistUseCase.CheckWhitelistUseCase,
    ) {
        public func execute(documentId : Document.DocumentId, reviewer : Principal) : async Result.Result<(), Text> {
            Debug.print("VerifyDocumentSourceUseCase: Verifying document with ID: " # debug_show (documentId));

            // Check if the reviewer is in the whitelist
            let isWhitelisted = await checkWhitelistUseCase.execute(reviewer);
            if (not isWhitelisted) {
                return #err("Reviewer is not in the whitelist of authorized verifiers");
            };

            let documentResult = await documentRepo.getDocument(documentId);
            switch (documentResult) {
                case (#ok(document)) {
                    Debug.print("VerifyDocumentSourceUseCase: Document found: " # debug_show (document));

                    // Check if the document has already been verified by this reviewer
                    let alreadyVerified = Array.find<Document.Review>(
                        document.verifiedBy,
                        func(review : Document.Review) : Bool {
                            Debug.print("Comparing reviewer: " # review.reviewer # " with " # Principal.toText(reviewer));
                            review.reviewer == Principal.toText(reviewer);
                        },
                    );

                    Debug.print("VerifyDocumentSourceUseCase: alreadyVerified: " # debug_show (alreadyVerified));

                    switch (alreadyVerified) {
                        case (?_) {
                            Debug.print("VerifyDocumentSourceUseCase: Document already verified by this reviewer");
                            return #err("Document already verified by this reviewer");
                        };
                        case (null) {
                            // Check if the reviewer has sufficient reputation in at least one of the document's categories
                            var hasRequiredReputation = false;
                            label a for (categoryId in document.categories.vals()) {
                                let reputationResult = await reputationRepo.getReputation(reviewer, categoryId);
                                Debug.print("VerifyDocumentSourceUseCase: reputationResult for categoryId: " # debug_show (categoryId) # ", result: " # debug_show (reputationResult));
                                switch (reputationResult) {
                                    case (?reputation) {
                                        if (reputation.score >= T.REPUTATION_UPDATE_THRESHOLD) {
                                            // Assume 10 is the minimum required reputation
                                            hasRequiredReputation := true;
                                            break a;
                                        };
                                    };
                                    case (null) {};
                                };
                            };

                            if (not hasRequiredReputation) {
                                return #err("Reviewer does not have sufficient reputation in the document's categories");
                            };

                            let sourceVerified = await verifySource(document.sourceUrl);
                            if (sourceVerified) {
                                let reputationResult = await updateReputationUseCase.assignFullReputation(document.user, document.categories[0]);
                                switch (reputationResult) {
                                    case (#ok(repValue)) {
                                        let newReview : Document.Review = {
                                            reviewer = Principal.toText(reviewer);
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
                                        Debug.print("VerifyDocumentSourceUseCase: Failed to assign full reputation: " # e);
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
