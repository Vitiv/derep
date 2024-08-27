import Reputation "../../domain/entities/Reputation";
import ReputationRepository "../../domain/repositories/ReputationRepository";
import User "../../domain/entities/User";
import Category "../../domain/entities/Category";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Text "mo:base/Text";

actor class ReputationRepositoryImpl() : async ReputationRepository.ReputationRepository {
    private stable var reputations : [(User.UserId, Category.CategoryId, Reputation.Reputation)] = [];

    private func equal(x : (User.UserId, Category.CategoryId), y : (User.UserId, Category.CategoryId)) : Bool {
        Principal.equal(x.0, y.0) and x.1 == y.1
    };

    private func hash(x : (User.UserId, Category.CategoryId)) : Nat32 {
        Principal.hash(x.0) ^ Text.hash(x.1);
    };

    private var reputationMap = HashMap.HashMap<(User.UserId, Category.CategoryId), Reputation.Reputation>(10, equal, hash);

    public shared query func getReputation(userId : User.UserId, categoryId : Category.CategoryId) : async ?Reputation.Reputation {
        reputationMap.get((userId, categoryId));
    };

    public shared func updateReputation(reputation : Reputation.Reputation) : async Bool {
        reputationMap.put((reputation.userId, reputation.categoryId), reputation);
        true;
    };

    public shared query func getUserReputations(userId : User.UserId) : async [Reputation.Reputation] {
        Iter.toArray(Iter.filter(reputationMap.vals(), func(r : Reputation.Reputation) : Bool { Principal.equal(r.userId, userId) }));
    };

    public shared query func getCategoryReputations(categoryId : Category.CategoryId) : async [Reputation.Reputation] {
        Iter.toArray(Iter.filter(reputationMap.vals(), func(r : Reputation.Reputation) : Bool { r.categoryId == categoryId }));
    };

    system func preupgrade() {
        reputations := Array.map<((User.UserId, Category.CategoryId), Reputation.Reputation), (User.UserId, Category.CategoryId, Reputation.Reputation)>(
            Iter.toArray(reputationMap.entries()),
            func((key, value) : ((User.UserId, Category.CategoryId), Reputation.Reputation)) : (User.UserId, Category.CategoryId, Reputation.Reputation) {
                (key.0, key.1, value);
            },
        );
    };

    system func postupgrade() {
        reputationMap := HashMap.fromIter<(User.UserId, Category.CategoryId), Reputation.Reputation>(
            Array.map<(User.UserId, Category.CategoryId, Reputation.Reputation), ((User.UserId, Category.CategoryId), Reputation.Reputation)>(
                reputations,
                func(entry : (User.UserId, Category.CategoryId, Reputation.Reputation)) : ((User.UserId, Category.CategoryId), Reputation.Reputation) {
                    ((entry.0, entry.1), entry.2);
                },
            ).vals(),
            10,
            equal,
            hash,
        );
        reputations := [];
    };
};
