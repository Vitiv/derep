import T "../entities/Types";

module {
    public type NotificationRepository = {
        storeNotification : (T.EventNotification) -> async ();
        getNotifications : (T.Namespace) -> async [T.EventNotification];
        clearNotifications : () -> async ();
    };
};
