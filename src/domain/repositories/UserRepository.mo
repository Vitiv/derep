import User "../entities/User";
import HashMap "mo:base/HashMap";

module {
    public type UserRepository = {
        var users : HashMap.HashMap<User.UserId, User.User>;

        createUser : (User.User) -> async Bool;
        getUser : (User.UserId) -> async ?User.User;
        updateUser : (User.User) -> async Bool;
        deleteUser : (User.UserId) -> async Bool;
        listUsers : () -> async [User.User];
        getUsersByUsername : (Text) -> async [User.User];
        clearAllUsers : () -> async Bool;
    };
};
