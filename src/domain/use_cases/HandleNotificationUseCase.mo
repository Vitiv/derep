import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import T "../entities/Types";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import Category "../entities/Category";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class HandleNotificationUseCase(
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
        updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
    ) {
        public func execute(notification : T.EventNotification) : async () {
            Debug.print("Processing event notification: " # debug_show (notification));

            if (notification.namespace == T.UPDATE_REPUTATION_NAMESPACE) {
                let parseResult = parseReputationUpdateNotification(notification);
                switch (parseResult) {
                    case (#ok(data)) {
                        let categories = await namespaceCategoryMapper.mapNamespaceToCategories(notification.namespace);

                        let categoriesToUpdate = if (categories.size() > 0) {
                            categories;
                        } else {
                            switch (data.category) {
                                case null { [] };
                                case (?cat) { [cat] };
                            };
                        };

                        // Get all parent ctaegories
                        var allCategories : [Category.CategoryId] = [];
                        for (category in categoriesToUpdate.vals()) {
                            // TODO collect unique categories only
                            let parentCategories = await namespaceCategoryMapper.getParentCategories(category);
                            allCategories := ArrayUtils.pushToArray(category, allCategories);
                            allCategories := ArrayUtils.appendArray(allCategories, parentCategories);
                        };

                        // Remove duplicates
                        let uniqueCategories = Buffer.Buffer<Category.CategoryId>(allCategories.size());
                        for (category in allCategories.vals()) {
                            if (not Buffer.contains(uniqueCategories, category, Text.equal)) {
                                uniqueCategories.add(category);
                            };
                        };
                        allCategories := Buffer.toArray(uniqueCategories);

                        for (category in allCategories.vals()) {
                            let updateResult = await updateReputationUseCase.execute(data.user, category, data.value);
                            switch (updateResult) {
                                case (#ok(_)) {
                                    Debug.print("Updated reputation for category " # debug_show (category));
                                };
                                case (#err(error)) {
                                    Debug.print("Failed to update reputation for category " # category # ": " # debug_show (error));
                                };
                            };
                        };
                    };
                    case (#err(error)) {
                        Debug.print("Failed to parse notification: " # error);
                    };
                };
            };
        };

        // Parse reputation update notification
        private func parseReputationUpdateNotification(notification : T.EventNotification) : Result.Result<T.ReputationUpdateInfo, Text> {
            switch (notification.data) {
                case (#Map(dataMap)) {
                    var user : ?Principal = null;
                    var category : ?Text = null;
                    var value : ?Int = null;
                    var verificationCanister : ?Principal = null;
                    var verificationMethod : ?Text = null;
                    var documentId : ?Nat = null;

                    for ((key, val) in dataMap.vals()) {
                        switch (key, val) {
                            case ("user", #Principal(p)) { user := ?p };
                            case ("category", #Text(t)) { category := ?t };
                            case ("value", #Int(i)) { value := ?i };
                            case ("verificationCanister", #Principal(p)) {
                                verificationCanister := ?p;
                            };
                            case ("verificationMethod", #Text(t)) {
                                verificationMethod := ?t;
                            };
                            case ("documentId", #Nat(n)) { documentId := ?n };
                            case _ { /* Ignore other fields */ };
                        };
                    };

                    switch (user, category, value, verificationCanister, verificationMethod, documentId) {
                        case (?u, c, ?v, ?vc, ?vm, ?d) {
                            #ok({
                                user = u;
                                category = c;
                                value = v;
                                verificationInfo = ?{
                                    canister = vc;
                                    method = vm;
                                    documentId = d;
                                };
                            });
                        };
                        case _ {
                            #err("Invalid or incomplete data in reputation update notification");
                        };
                    };
                };
                case _ {
                    #err("Unexpected data format in reputation update notification");
                };
            };
        };

    };
};
