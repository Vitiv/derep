// import T "../entities/Types";
// import Debug "mo:base/Debug";
// import Text "mo:base/Text";
// import Principal "mo:base/Principal";
// import Array "mo:base/Array";
// import Iter "mo:base/Iter";
// import ArrayUtils "../../../utils/ArrayUtils";
// import CategoryRepository "../repositories/CategoryRepository";
// import UpdateReputationUseCase "UpdateReputationUseCase";

// module {
//     public class HandleReputationEventUseCase(
//         categoryRepo : CategoryRepository.CategoryRepository,
//         updateReputationUseCase : UpdateReputationUseCase.UpdateReputationUseCase,
//     ) {
//         public func execute(notification : T.EventNotification) : async () {
//             Debug.print("HandleReputationEventUseCase: Processing event notification: " # debug_show (notification));

//             switch (notification.data) {
//                 case (#Map(dataMap)) {
//                     let user = extractPrincipal(dataMap, "user");
//                     let category = extractText(dataMap, "category");
//                     let value = extractInt(dataMap, "value");

//                     switch (user, category, value) {
//                         case (?u, ?c, ?v) {
//                             Debug.print("Ensuring category hierarchy for: " # c);
//                             let categoriesToUpdate = await ensureCategoryHierarchy(c);
//                             Debug.print("Categories to update: " # debug_show (categoriesToUpdate));

//                             for (currentCategoryId in categoriesToUpdate.vals()) {
//                                 let result = await updateReputationUseCase.execute(u, currentCategoryId, v);
//                                 switch (result) {
//                                     case (#ok(_)) {
//                                         Debug.print("Updated reputation for category " # currentCategoryId);
//                                     };
//                                     case (#err(error)) {
//                                         Debug.print("Failed to update reputation for category " # currentCategoryId # ": " # error);
//                                     };
//                                 };
//                             };
//                         };
//                         case _ {
//                             Debug.print("Incomplete data in event notification");
//                         };
//                     };
//                 };
//                 case _ {
//                     Debug.print("Unexpected data format in event notification");
//                 };
//             };
//         };

//         private func extractPrincipal(dataMap : [(Text, T.ICRC16)], key : Text) : ?Principal {
//             for ((k, v) in dataMap.vals()) {
//                 if (k == key) {
//                     switch (v) {
//                         case (#Principal(p)) { return ?p };
//                         case _ {};
//                     };
//                 };
//             };
//             null;
//         };

//         private func extractText(dataMap : [(Text, T.ICRC16)], key : Text) : ?Text {
//             for ((k, v) in dataMap.vals()) {
//                 if (k == key) {
//                     switch (v) {
//                         case (#Text(t)) { return ?t };
//                         case _ {};
//                     };
//                 };
//             };
//             null;
//         };

//         private func extractInt(dataMap : [(Text, T.ICRC16)], key : Text) : ?Int {
//             for ((k, v) in dataMap.vals()) {
//                 if (k == key) {
//                     switch (v) {
//                         case (#Int(i)) { return ?i };
//                         case _ {};
//                     };
//                 };
//             };
//             null;
//         };

//         private func updateReputationWithVerification(user : Principal, categoryId : Text, value : Int, namespace : T.Namespace) : async () {
//             Debug.print("updateReputationWithVerification: start");
//             let categoriesToUpdate = await ensureCategoryHierarchy(categoryId);

//             for (currentCategoryId in categoriesToUpdate.vals()) {
//                 let result = await updateReputationUseCase.execute(user, currentCategoryId, value);
//                 switch (result) {
//                     case (#ok(_)) {
//                         Debug.print("Updated reputation for category " # currentCategoryId);
//                     };
//                     case (#err(error)) {
//                         Debug.print("Failed to update reputation for category " # currentCategoryId # ": " # error);
//                     };
//                 };
//             };
//         };

//         private func ensureCategoryHierarchy(categoryId : Text) : async [Text] {
//             Debug.print("ensureCategoryHierarchy: start");

//             var categories = [categoryId];
//             var currentCategoryId = categoryId;

//             label c loop {
//                 let parts = Iter.toArray(Text.split(currentCategoryId, #char '.'));
//                 if (parts.size() <= 1) {
//                     break c;
//                 };

//                 let parentParts = Array.subArray(parts, 0, parts.size() - 1);
//                 let parentId = Text.join(".", parentParts.vals());
//                 Debug.print("ensureCategoryHierarchy: parentId: " # debug_show (parentId));
//                 switch (await categoryRepo.getCategory(parentId)) {
//                     case (null) {
//                         // create category
//                         let newCategory = {
//                             id = parentId;
//                             name = "Auto-generated category " # parentId;
//                             description = "Automatically created parent category";
//                             parentId = null;
//                         };
//                         ignore await categoryRepo.createCategory(newCategory);
//                         Debug.print("ensureCategoryHierarchy: Created new parent category: " # parentId);
//                     };
//                     case (?cat) {
//                         // category exist
//                         Debug.print("ensureCategoryHierarchy: Category exists: " # debug_show (cat));
//                     };
//                 };

//                 categories := ArrayUtils.pushToArray(parentId, categories);
//                 currentCategoryId := parentId;
//             };

//             Array.reverse(categories);
//         };
//     };
// };
