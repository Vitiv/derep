import Principal "mo:base/Principal";

module {
    public type VerifierWhitelistRepository = {
        add : (verifier : Principal) -> async ();
        remove : (verifier : Principal) -> async ();
        contains : (verifier : Principal) -> async Bool;
        getAll : () -> async [Principal];
        setWhitelist : (newWhitelist : [(Principal, Bool)]) -> async ();
        getSerializedWhitelist : () -> async [(Principal, Bool)];
    };
};
