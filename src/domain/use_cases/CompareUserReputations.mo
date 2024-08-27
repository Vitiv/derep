import Result "mo:base/Result";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Principal "mo:base/Principal";

import User "../entities/User";
import Reputation "../entities/Reputation";
import Category "../entities/Category";
import UserRepository "../repositories/UserRepository";
import ReputationRepository "../repositories/ReputationRepository";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class CompareUserReputations(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
    ) {
        public type UserId = User.UserId;
        public type CategoryId = Category.CategoryId;

        public type ComparisonResult = {
            categoryId : CategoryId;
            categoryName : Text;
            user1Score : Int;
            user2Score : Int;
            difference : Int;
        };

        public type ComparisonReport = {
            user1Id : UserId;
            user2Id : Text;
            results : [ComparisonResult];
        };

        public func compareWithUser(userId1 : UserId, userId2 : UserId) : async Result.Result<ComparisonReport, Text> {
            let user1Opt = await userRepo.getUser(userId1);
            let user2Opt = await userRepo.getUser(userId2);

            switch (user1Opt, user2Opt) {
                case (null, _) { #err("User 1 not found") };
                case (_, null) { #err("User 2 not found") };
                case (?user1, ?user2) {
                    let categories = await categoryRepo.listCategories();
                    var results : [ComparisonResult] = [];

                    for (category in categories.vals()) {
                        let rep1 = await reputationRepo.getReputation(userId1, category.id);
                        let rep2 = await reputationRepo.getReputation(userId2, category.id);

                        let score1 = switch (rep1) {
                            case (?r) { r.score };
                            case (null) { 0 };
                        };

                        let score2 = switch (rep2) {
                            case (?r) { r.score };
                            case (null) { 0 };
                        };

                        let comparisonResult : ComparisonResult = {
                            categoryId = category.id;
                            categoryName = category.name;
                            user1Score = score1;
                            user2Score = score2;
                            difference = score1 - score2;
                        };

                        results := Array.append(results, [comparisonResult]);
                    };

                    let report : ComparisonReport = {
                        user1Id = userId1;
                        user2Id = Principal.toText(userId2);
                        results = results;
                    };

                    #ok(report);
                };
            };
        };

        public func compareWithAverage(userId : UserId) : async Result.Result<ComparisonReport, Text> {
            let userOpt = await userRepo.getUser(userId);

            switch (userOpt) {
                case (null) { #err("User not found") };
                case (?user) {
                    let categories = await categoryRepo.listCategories();
                    var results : [ComparisonResult] = [];

                    for (category in categories.vals()) {
                        let userRep = await reputationRepo.getReputation(userId, category.id);
                        let userScore = switch (userRep) {
                            case (?r) { r.score };
                            case (null) { 0 };
                        };

                        let allReputations = await reputationRepo.getCategoryReputations(category.id);
                        let totalScore = Array.foldLeft<Reputation.Reputation, Int>(allReputations, 0, func(acc, rep) { acc + rep.score });
                        let averageScore = if (allReputations.size() > 0) {
                            totalScore / allReputations.size();
                        } else { 0 };

                        let comparisonResult : ComparisonResult = {
                            categoryId = category.id;
                            categoryName = category.name;
                            user1Score = userScore;
                            user2Score = averageScore;
                            difference = userScore - averageScore;
                        };

                        results := Array.append(results, [comparisonResult]);
                    };

                    let report : ComparisonReport = {
                        user1Id = userId;
                        user2Id = "SYSTEM_AVERAGE";
                        results = results;
                    };

                    #ok(report);
                };
            };
        };
    };
};
