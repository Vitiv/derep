import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import T "../entities/Types";
import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import UpdateReputationUseCase "./UpdateReputationUseCase";
import Category "../entities/Category";
import ArrayUtils "../../../utils/ArrayUtils";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class HandleNotificationUseCase(
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
        updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
        categoryRepo : CategoryRepository.CategoryRepository,
    ) {
        public func execute(notification : T.EventNotification) : async () {
            Debug.print("Processing event notification: " # debug_show (notification));

            if (notification.namespace == T.UPDATE_REPUTATION_NAMESPACE) {
                let parseResult = parseReputationUpdateNotification(notification);
                switch (parseResult) {
                    case (#ok(data)) {
                        Debug.print("Parsed reputation update data: " # debug_show (data));

                        let documentUrl = getDocumentUrlFromNotification(notification);
                        let categories = await namespaceCategoryMapper.mapNamespaceToCategories(notification.namespace, documentUrl, data.category);
                        Debug.print("Mapped categories: " # debug_show (categories));

                        for (category in categories.vals()) {
                            if (category != "") {
                                let existCategories = await ensureCategoryHierarchy(category);
                                Debug.print("HandleNotificationUseCase: existCategories " # debug_show (existCategories));
                                let updateResult = await updateReputationUseCase.execute(data.user, category, data.value);
                                switch (updateResult) {
                                    case (#ok(_)) {
                                        Debug.print("Updated reputation for category " # debug_show (category));
                                    };
                                    case (#err(error)) {
                                        Debug.print("Failed to update reputation for category " # category # ": " # debug_show (error));
                                    };
                                };
                            } else {
                                Debug.print("Skipping update for empty category");
                            };
                        };
                    };
                    case (#err(error)) {
                        Debug.print("Failed to parse notification: " # error);
                    };
                };
            } else {
                Debug.print("Notification namespace not recognized: " # notification.namespace);
            };
        };

        private func getDocumentUrlFromNotification(notification : T.EventNotification) : ?Text {
            // Implement logic to extract document URL from notification
            // This is a placeholder implementation
            null;
        };

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

        private func ensureCategoryHierarchy(categoryId : Text) : async [Text] {
            var categories = [categoryId];
            var currentCategoryId = categoryId;

            await ensureCategory(categoryId);

            while (Text.contains(currentCategoryId, #char '.')) {
                let parts = Iter.toArray(Text.split(currentCategoryId, #char '.'));
                let parentParts = Array.subArray(parts, 0, parts.size() - 1);
                let parentId = Text.join(".", parentParts.vals());

                switch (await categoryRepo.getCategory(parentId)) {
                    case (null) {
                        let newCategory = {
                            id = parentId;
                            name = "Auto-generated category " # parentId;
                            description = "Automatically created parent category";
                            parentId = null;
                        };
                        let created = await categoryRepo.createCategory(newCategory);
                        if (not created) {
                            Debug.print("Failed to create category: " # parentId);
                        } else {
                            Debug.print("Created new parent category: " # parentId);
                        };
                    };
                    case (?_) {
                        Debug.print("Category already exists: " # parentId);
                    };
                };

                categories := ArrayUtils.pushToArray(parentId, categories);
                currentCategoryId := parentId;
            };

            Array.reverse(categories);
        };

        private func ensureCategory(categoryId : Text) : async () {
            switch (await categoryRepo.getCategory(categoryId)) {
                case (null) {
                    let newCategory = {
                        id = categoryId;
                        name = "Auto-generated category " # categoryId;
                        description = "Automatically created category";
                        parentId = null;
                    };
                    let created = await categoryRepo.createCategory(newCategory);
                    if (not created) {
                        Debug.print("Failed to create category: " # categoryId);
                    } else {
                        Debug.print("Created new category: " # categoryId);
                    };
                };
                case (?_) {
                    Debug.print("Category already exists: " # categoryId);
                };
            };
        };
    };
};
