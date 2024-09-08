import Reputation "../../domain/entities/Reputation";
import User "../../domain/entities/User";
import Category "../../domain/entities/Category";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

module {
    public class ReputationRepositoryImpl() {
        public func keyEqual(k1 : (User.UserId, Category.CategoryId), k2 : (User.UserId, Category.CategoryId)) : Bool {
            Principal.equal(k1.0, k2.0) and k1.1 == k2.1
        };

        public func keyHash(k : (User.UserId, Category.CategoryId)) : Nat32 {
            Principal.hash(k.0) ^ Text.hash(k.1);
        };

        public var reputations = HashMap.HashMap<(User.UserId, Category.CategoryId), Reputation.Reputation>(10, keyEqual, keyHash);

        public func getReputation(userId : User.UserId, categoryId : Category.CategoryId) : async ?Reputation.Reputation {
            reputations.get((userId, categoryId));
        };

        public func updateReputation(reputation : Reputation.Reputation) : async Bool {
            reputations.put((reputation.userId, reputation.categoryId), reputation);
            true;
        };

        public func getUserReputations(userId : User.UserId) : async [Reputation.Reputation] {
            Iter.toArray(
                Iter.filter(
                    reputations.vals(),
                    func(rep : Reputation.Reputation) : Bool {
                        Principal.equal(rep.userId, userId);
                    },
                )
            );
        };

        public func getCategoryReputations(categoryId : Category.CategoryId) : async [Reputation.Reputation] {
            Iter.toArray(
                Iter.filter(
                    reputations.vals(),
                    func(rep : Reputation.Reputation) : Bool {
                        rep.categoryId == categoryId;
                    },
                )
            );
        };

        public func getAllReputations() : async [Reputation.Reputation] {
            Iter.toArray(reputations.vals());
        };

        public func getTopUsersByCategoryId(categoryId : Category.CategoryId, limit : Nat) : async [(User.UserId, Int)] {
            let categoryReps = await getCategoryReputations(categoryId);
            let sorted = Array.sort(
                categoryReps,
                func(a : Reputation.Reputation, b : Reputation.Reputation) : Order.Order {
                    if (a.score > b.score) { #less } else if (a.score < b.score) {
                        #greater;
                    } else { #equal };
                },
            );
            let sliceEnd = Nat.min(limit, sorted.size());
            Array.map<Reputation.Reputation, (User.UserId, Int)>(
                Iter.toArray(Array.slice<Reputation.Reputation>(sorted, 0, sliceEnd)),
                func(rep : Reputation.Reputation) : (User.UserId, Int) {
                    (rep.userId, rep.score);
                },
            );
        };

        public func getTotalUserReputation(userId : User.UserId) : async Int {
            let userReps = await getUserReputations(userId);
            Array.foldLeft<Reputation.Reputation, Int>(userReps, 0, func(acc, rep) { acc + rep.score });
        };

        public func clearAllReputations() : async Bool {
            reputations := HashMap.HashMap<(User.UserId, Category.CategoryId), Reputation.Reputation>(10, keyEqual, keyHash);
            true;
        };

        public func deleteUserReputations(userId : User.UserId) : async Bool {
            var deleted = false;
            for ((key, _) in reputations.entries()) {
                if (Principal.equal(key.0, userId)) {
                    ignore reputations.remove(key);
                    deleted := true;
                };
            };
            deleted;
        };

        public func deleteCategoryReputations(categoryId : Category.CategoryId) : async Bool {
            var deleted = false;
            for ((key, _) in reputations.entries()) {
                if (key.1 == categoryId) {
                    ignore reputations.remove(key);
                    deleted := true;
                };
            };
            deleted;
        };
    };
};
