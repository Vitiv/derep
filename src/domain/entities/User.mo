import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {
    public type UserId = Principal;

    public type User = {
        id : UserId;
        username : Text;
        registrationDate : Int;
    };

    public func createUser(id : UserId, username : Text) : User {
        {
            id = id;
            username = username;
            registrationDate = Time.now();
        };
    };
};
