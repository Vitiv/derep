import T "../../domain/entities/Types";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class NotificationRepositoryImpl() {
        public var notificationMap = HashMap.HashMap<T.Namespace, [T.EventNotification]>(10, Text.equal, Text.hash);

        public func storeNotification(notification : T.EventNotification) : async () {
            let namespace = notification.namespace;
            switch (notificationMap.get(namespace)) {
                case null notificationMap.put(namespace, [notification]);
                case (?existingNotifications) {
                    let newList = ArrayUtils.pushToArray<T.EventNotification>(notification, existingNotifications);
                    notificationMap.put(namespace, newList);
                };
            };
        };

        public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
            switch (notificationMap.get(namespace)) {
                case null [];
                case (?notifications) notifications;
            };
        };

        public func clearNotifications() : async () {
            notificationMap := HashMap.HashMap<T.Namespace, [T.EventNotification]>(10, Text.equal, Text.hash);
        };
    };
};
