import User "../../domain/entities/User";

module {
    public type UserRepository = actor {
        createUser : (User.User) -> async Bool;
        getUser : query (User.UserId) -> async ?User.User;
        updateUser : (User.User) -> async Bool;
        deleteUser : (User.UserId) -> async Bool;
    };
};
