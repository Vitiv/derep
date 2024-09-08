import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";

module {
    public type VerifierWhitelistRepository = {
        var whitelist : HashMap.HashMap<Principal, Bool>;
        add : (verifier : Principal) -> async ();
        remove : (verifier : Principal) -> async ();
        contains : (verifier : Principal) -> async Bool;
        getAll : () -> async [Principal];
        setWhitelist : (newWhitelist : [(Principal, Bool)]) -> async ();
        getSerializedWhitelist : () -> async [(Principal, Bool)];
    };
};
