import Principal "mo:base/Principal";
import Result "mo:base/Result";
import VerifierWhitelistRepository "../repositories/VerifierWhitelistRepository";

module {
    public class RemoveFromWhitelistUseCase(repository : VerifierWhitelistRepository.VerifierWhitelistRepository) {
        public func execute(verifier : Principal) : async Result.Result<(), Text> {
            if (await repository.contains(verifier)) {
                await repository.remove(verifier);
                #ok(());
            } else {
                #err("Verifier not found in whitelist");
            };
        };
    };
};
