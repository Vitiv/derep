import Principal "mo:base/Principal";
import VerifierWhitelistRepository "../repositories/VerifierWhitelistRepository";

module {
    public class GetWhitelistUseCase(repository : VerifierWhitelistRepository.VerifierWhitelistRepository) {
        public func execute() : async [Principal] {
            await repository.getAll();
        };
    };
};
