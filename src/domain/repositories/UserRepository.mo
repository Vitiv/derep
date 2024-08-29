import User "../entities/User";

module {
    public type UserRepository = {
        createUser : (User.User) -> async Bool;
        getUser : (User.UserId) -> async ?User.User;
        updateUser : (User.User) -> async Bool;
        deleteUser : (User.UserId) -> async Bool;
        listUsers : () -> async [User.User];
        getUsersByUsername : (Text) -> async [User.User];
        clearAllUsers : () -> async Bool;
    };
};
