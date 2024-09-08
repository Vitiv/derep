import Principal "mo:base/Principal";
import VerifierWhitelistRepository "../repositories/VerifierWhitelistRepository";

module {
    public class CheckWhitelistUseCase(repository : VerifierWhitelistRepository.VerifierWhitelistRepository) {
        public func execute(verifier : Principal) : async Bool {
            await repository.contains(verifier);
        };
    };
};
