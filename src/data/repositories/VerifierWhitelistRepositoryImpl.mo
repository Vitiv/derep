import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import VerifierWhitelistRepository "../../domain/repositories/VerifierWhitelistRepository";

module {
    public class VerifierWhitelistRepositoryImpl() : VerifierWhitelistRepository.VerifierWhitelistRepository {
        public var whitelist = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);

        public func add(verifier : Principal) : async () {
            whitelist.put(verifier, true);
        };

        public func remove(verifier : Principal) : async () {
            whitelist.delete(verifier);
        };

        public func contains(verifier : Principal) : async Bool {
            switch (whitelist.get(verifier)) {
                case (?isWhitelisted) { isWhitelisted };
                case (null) { false };
            };
        };

        public func getAll() : async [Principal] {
            Iter.toArray(whitelist.keys());
        };

        public func setWhitelist(newWhitelist : [(Principal, Bool)]) : async () {
            whitelist := HashMap.fromIter<Principal, Bool>(newWhitelist.vals(), 10, Principal.equal, Principal.hash);
        };

        public func getSerializedWhitelist() : async [(Principal, Bool)] {
            Iter.toArray(whitelist.entries());
        };
    };
};
