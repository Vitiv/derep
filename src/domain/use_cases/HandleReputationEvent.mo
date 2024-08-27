import T "../entities/Types";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Category "../entities/Category";
import ReputationRepository "../repositories/ReputationRepository";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class HandleReputationEventUseCase(
        reputationRepo : ReputationRepository.ReputationRepository,
        categoryRepo : CategoryRepository.CategoryRepository,
    ) {
        public func execute(notification : T.EventNotification) : async () {
            Debug.print("Processing event notification: " # debug_show (notification));

            // Verify the source of the event (you might want to implement a whitelist check here)
            Debug.print("Event source: " # Principal.toText(notification.source));

            // Extract data from ICRC16
            switch (notification.data) {
                case (#Map(dataMap)) {
                    let user = extractPrincipal(dataMap, "user");
                    let category = extractText(dataMap, "category");
                    let value = extractInt(dataMap, "value");

                    switch (user, category, value) {
                        case (?u, ?c, ?v) {
                            await updateReputationWithVerification(u, c, v, notification.namespace);
                        };
                        case _ {
                            Debug.print("Incomplete data in event notification");
                        };
                    };
                };
                case _ {
                    Debug.print("Unexpected data format in event notification");
                };
            };
        };

        private func extractPrincipal(dataMap : [(Text, T.ICRC16)], key : Text) : ?Principal {
            for ((k, v) in dataMap.vals()) {
                if (k == key) {
                    switch (v) {
                        case (#Principal(p)) { return ?p };
                        case _ {};
                    };
                };
            };
            null;
        };

        private func extractText(dataMap : [(Text, T.ICRC16)], key : Text) : ?Text {
            for ((k, v) in dataMap.vals()) {
                if (k == key) {
                    switch (v) {
                        case (#Text(t)) { return ?t };
                        case _ {};
                    };
                };
            };
            null;
        };

        private func extractInt(dataMap : [(Text, T.ICRC16)], key : Text) : ?Int {
            for ((k, v) in dataMap.vals()) {
                if (k == key) {
                    switch (v) {
                        case (#Int(i)) { return ?i };
                        case _ {};
                    };
                };
            };
            null;
        };

        private func updateReputationWithVerification(user : Principal, categoryId : Text, value : Int, namespace : T.Namespace) : async () {
            // Verify the category by matching namespace
            let categories = await categoryRepo.listCategories();
            let matchingCategory = Array.find(
                categories,
                func(cat : Category.Category) : Bool {
                    cat.id == categoryId;
                },
            );

            switch (matchingCategory) {
                case (?_) {
                    let currentReputation = await reputationRepo.getReputation(user, categoryId);
                    let newReputation = switch (currentReputation) {
                        case (null) {
                            {
                                userId = user;
                                categoryId = categoryId;
                                score = value;
                                lastUpdated = Time.now();
                            };
                        };
                        case (?rep) {
                            {
                                userId = rep.userId;
                                categoryId = rep.categoryId;
                                score = rep.score + value;
                                lastUpdated = Time.now();
                            };
                        };
                    };

                    let success = await reputationRepo.updateReputation(newReputation);
                    if (not success) {
                        // log error
                    };
                };
                case (null) {
                    Debug.print("No category found for namespace: " # namespace);
                };
            };
        };

    };
};
