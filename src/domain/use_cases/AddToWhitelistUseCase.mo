import Principal "mo:base/Principal";
import Result "mo:base/Result";
import VerifierWhitelistRepository "../repositories/VerifierWhitelistRepository";

module {
    public class AddToWhitelistUseCase(repository : VerifierWhitelistRepository.VerifierWhitelistRepository) {
        public func execute(verifier : Principal) : async Result.Result<(), Text> {
            if (await repository.contains(verifier)) {
                #err("Verifier already in whitelist");
            } else {
                await repository.add(verifier);
                #ok(());
            };
        };
    };
};
