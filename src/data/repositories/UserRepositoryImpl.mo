import User "../../domain/entities/User";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

module {
    public class UserRepositoryImpl() {
        public var users = HashMap.HashMap<User.UserId, User.User>(10, Principal.equal, Principal.hash);

        public func createUser(user : User.User) : async Bool {
            switch (users.get(user.id)) {
                case (?_) { false }; // User already exists
                case null {
                    users.put(user.id, user);
                    true;
                };
            };
        };

        public func getUser(id : User.UserId) : async ?User.User {
            users.get(id);
        };

        public func updateUser(user : User.User) : async Bool {
            switch (users.get(user.id)) {
                case null { false }; // User doesn't exist
                case (?_) {
                    users.put(user.id, user);
                    true;
                };
            };
        };

        public func clearAllUsers() : async Bool {
            users := HashMap.HashMap<User.UserId, User.User>(10, Principal.equal, Principal.hash);
            true;
        };

        public func deleteUser(id : User.UserId) : async Bool {
            switch (users.remove(id)) {
                case (null) { false };
                case (?_) { true };
            };
        };

        public func listUsers() : async [User.User] {
            Iter.toArray(users.vals());
        };

        public func getUsersByUsername(username : Text) : async [User.User] {
            Iter.toArray(
                Iter.filter(
                    users.vals(),
                    func(user : User.User) : Bool {
                        user.username == username;
                    },
                )
            );
        };
    };
};
