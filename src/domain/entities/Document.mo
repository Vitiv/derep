import Principal "mo:base/Principal";

module {
    public type DocumentId = Nat;
    public type Review = {
        reviewer : Text;
        date : Int;
        reputation : Int;
    };

    public type Document = {
        id : DocumentId;
        user : Principal;
        source : Text;
        sourceUrl : ?Text;
        content : Blob;
        name : Text;
        contentType : Text;
        size : Nat;
        hash : Text;
        createdAt : Int;
        updatedAt : Int;
        verifiedBy : [Review];
        previousVersion : ?DocumentId;
    };
};
