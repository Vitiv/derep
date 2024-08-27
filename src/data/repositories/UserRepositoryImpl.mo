import User "../../domain/entities/User";
import UserRepository "../../domain/repositories/UserRepository";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

actor class UserRepositoryImpl() : async UserRepository.UserRepository {
    private stable var users : [(User.UserId, User.User)] = [];
    private var userMap = HashMap.HashMap<User.UserId, User.User>(10, Principal.equal, Principal.hash);

    public shared func createUser(user : User.User) : async Bool {
        if (userMap.get(user.id) != null) {
            return false; // User already exists
        };
        userMap.put(user.id, user);
        true;
    };

    public query func getUser(userId : User.UserId) : async ?User.User {
        userMap.get(userId);
    };

    public shared func updateUser(user : User.User) : async Bool {
        switch (userMap.get(user.id)) {
            case (null) { false }; // User doesn't exist
            case (?_) {
                userMap.put(user.id, user);
                true;
            };
        };
    };

    public shared func deleteUser(userId : User.UserId) : async Bool {
        switch (userMap.remove(userId)) {
            case (null) { false }; // User doesn't exist
            case (?_) { true };
        };
    };

    system func preupgrade() {
        users := Iter.toArray(userMap.entries());
    };

    system func postupgrade() {
        userMap := HashMap.fromIter<User.UserId, User.User>(users.vals(), 10, Principal.equal, Principal.hash);
        users := [];
    };
};
