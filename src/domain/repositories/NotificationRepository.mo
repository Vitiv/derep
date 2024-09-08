import T "../entities/Types";
import HashMap "mo:base/HashMap";

module {
    public type NotificationRepository = {
        var notificationMap : HashMap.HashMap<T.Namespace, [T.EventNotification]>;
        storeNotification : (T.EventNotification) -> async ();
        getNotifications : (T.Namespace) -> async [T.EventNotification];
        clearNotifications : () -> async ();
    };
};
