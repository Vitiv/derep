import Blob "mo:base/Blob";

module {
    public type IncomingFile = {
        name : Text;
        content : Blob;
        contentType : Text;
        user : Text;
        sourceUrl : ?Text;
        categories : [Text];
    };
};
