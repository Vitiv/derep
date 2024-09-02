import Principal "mo:base/Principal";

module {
    public type ReputationChange = {
        userId : Principal;
        categoryId : Text;
        value : Int;
        timestamp : Int;
    };
};
