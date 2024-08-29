import T "../entities/Types";
import NotificationRepository "../repositories/NotificationRepository";

module {
    public class NotificationUseCase(notificationRepo : NotificationRepository.NotificationRepository) {
        public func storeNotification(notification : T.EventNotification) : async () {
            await notificationRepo.storeNotification(notification);
        };

        public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
            await notificationRepo.getNotifications(namespace);
        };

        public func clearNotifications() : async () {
            await notificationRepo.clearNotifications();
        };
    };
};
