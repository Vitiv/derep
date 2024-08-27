import User "../../domain/entities/User";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

module {
    public class UserRepositoryImpl() {
        private var users = HashMap.HashMap<User.UserId, User.User>(10, Principal.equal, Principal.hash);

        public func createUser(user : User.User) : Bool {
            switch (users.get(user.id)) {
                case (?_) { false }; // User already exists
                case null {
                    users.put(user.id, user);
                    true;
                };
            };
        };

        public func getUser(id : User.UserId) : ?User.User {
            users.get(id);
        };

        public func updateUser(user : User.User) : Bool {
            switch (users.get(user.id)) {
                case null { false }; // User doesn't exist
                case (?_) {
                    users.put(user.id, user);
                    true;
                };
            };
        };

        public func deleteUser(id : User.UserId) : Bool {
            switch (users.remove(id)) {
                case null { false }; // User doesn't exist
                case (?_) { true };
            };
        };

        public func listUsers() : [User.User] {
            Iter.toArray(users.vals());
        };

        // Additional helper method
        public func getUsersByUsername(username : Text) : [User.User] {
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
