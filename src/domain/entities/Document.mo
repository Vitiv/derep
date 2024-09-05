import Principal "mo:base/Principal";

module {
    public type DocumentId = Nat;

    public type Document = {
        id : DocumentId;
        user : Principal;
        source : Text;
        content : Blob;
        name : Text;
        contentType : Text;
        size : Nat;
        hash : Text;
        createdAt : Int;
        updatedAt : Int;
    };
};
