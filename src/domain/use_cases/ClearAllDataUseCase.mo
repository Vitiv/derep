import UserRepository "../repositories/UserRepository";
import ReputationRepository "../repositories/ReputationRepository";
import CategoryRepository "../repositories/CategoryRepository";
import NotificationRepository "../repositories/NotificationRepository";
import Result "mo:base/Result";
import Error "mo:base/Error";

module {
    public class ClearAllDataUseCase(
        userRepo : UserRepository.UserRepository,
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
        notificationRepo : NotificationRepository.NotificationRepository,
    ) {
        public func execute() : async Result.Result<(), Text> {
            try {
                ignore await userRepo.clearAllUsers();
                ignore await reputationRepo.clearAllReputations();
                ignore await categoryRepo.clearAllCategories();
                await notificationRepo.clearNotifications();
                #ok(());
            } catch (error) {
                #err("Failed to clear all data: " # Error.message(error));
            };
        };
    };
};
