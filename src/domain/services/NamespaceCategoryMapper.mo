import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

import Category "../entities/Category";
import CategoryRepository "../repositories/CategoryRepository";
import ArrayUtils "../../../utils/ArrayUtils";
import NamespaceCategoryMappingRepository "../repositories/NamespaceCategoryMappingRepository";
import DocumentClassifier "./DocumentClassifier";

module {
    public class NamespaceCategoryMapper(
        categoryRepo : CategoryRepository.CategoryRepository,
        namespaceMappingRepo : NamespaceCategoryMappingRepository.NamespaceCategoryMappingRepository,
        documentClassifier : DocumentClassifier.DocumentClassifier,
    ) {
        public func mapNamespaceToCategories(namespace : Text, documentUrl : ?Text, providedCategoryId : ?Text) : async [Category.CategoryId] {
            var matchedCategories = Buffer.Buffer<Category.CategoryId>(0);

            switch (providedCategoryId) {
                case (?catId) {
                    // Check if the provided category exists
                    switch (await categoryRepo.getCategory(catId)) {
                        case (?_) {
                            // Category exists, use it
                            matchedCategories.add(catId);
                        };
                        case (null) {
                            // Category doesn't exist, create it
                            let newCategory = {
                                id = catId;
                                name = "Auto-generated category " # catId;
                                description = "Automatically created category from provided ID";
                                parentId = null;
                            };
                            let created = await categoryRepo.createCategory(newCategory);
                            if (created) {
                                Debug.print("NamespaceCategoryMapper: Created new category: " # catId);
                                matchedCategories.add(catId);
                            } else {
                                Debug.print("NamespaceCategoryMapper: Failed to create category: " # catId);
                            };
                        };
                    };
                };
                case (null) {
                    // No category provided, fall back to namespace-based mapping
                    let predefinedCategories = await namespaceMappingRepo.getCategoriesForNamespace(namespace);
                    for (category in predefinedCategories.vals()) {
                        matchedCategories.add(category);
                    };

                    if (matchedCategories.size() == 0) {
                        let inferredCategories = inferCategoriesFromNamespace(namespace);
                        for (category in inferredCategories.vals()) {
                            matchedCategories.add(category);
                        };
                    };

                    if (matchedCategories.size() == 0 and documentUrl != null) {
                        let classifiedCategories = await documentClassifier.classifyDocument(Option.get(documentUrl, ""));
                        for (category in classifiedCategories.vals()) {
                            matchedCategories.add(category);
                        };
                    };

                    if (matchedCategories.size() == 0) {
                        let newCategoryId = await createCategoryFromNamespace(namespace);
                        matchedCategories.add(newCategoryId);
                    };
                };
            };

            // Get all parent categories
            let allCategories = Buffer.Buffer<Category.CategoryId>(0);
            for (categoryId in matchedCategories.vals()) {
                if (categoryId != "") {
                    let parents = await getParentCategories(categoryId);
                    for (parent in parents.vals()) {
                        if (not Buffer.contains<Category.CategoryId>(allCategories, parent, Text.equal)) {
                            allCategories.add(parent);
                        };
                    };
                    if (not Buffer.contains<Category.CategoryId>(allCategories, categoryId, Text.equal)) {
                        allCategories.add(categoryId);
                    };
                };
            };

            Buffer.toArray(allCategories);
        };

        private func inferCategoriesFromNamespace(namespace : Text) : [Category.CategoryId] {
            // Implement logic to infer categories from namespace
            // For example, if namespace ends with "icdevs", add "Motoko" and "Internet Computer" categories
            let categories = Buffer.Buffer<Category.CategoryId>(0);
            if (Text.endsWith(namespace, #text "icdevs")) {
                categories.add("1.2.3.4"); // Assuming "1.2.3.4" is the ID for Motoko
                categories.add("1.2.2"); // Assuming "1.2.2" is the ID for Internet Computer
            };
            // Add more rules as needed
            Buffer.toArray(categories);
        };

        private func createCategoryFromNamespace(namespace : Text) : async Category.CategoryId {
            let newCategory = {
                id = namespace;
                name = "Auto-generated category " # namespace;
                description = "Automatically created category from namespace";
                parentId = ?getParentId(namespace);
            };
            let created = await categoryRepo.createCategory(newCategory);
            if (created) {
                Debug.print("NamespaceCategoryMapper: Created new category: " # namespace);
                namespace;
            } else {
                Debug.print("NamespaceCategoryMapper: Failed to create category: " # namespace);
                "";
            };
        };

        // // public func mapNamespaceToCategories(namespace : Text) : async [Category.CategoryId] {
        // //     var matchedCategories : [Category.CategoryId] = [];
        // //     var currentNamespace = namespace;

        // //     while (Text.size(currentNamespace) > 0) {
        // //         switch (await categoryRepo.getCategory(currentNamespace)) {
        // //             case (?category) {
        // //                 matchedCategories := ArrayUtils.pushToArray(category.id, matchedCategories);
        // //             };
        // //             case (null) {
        // //                 if (currentNamespace == namespace) {
        // //                     // Create new category if it doesn't exist
        // //                     let newCategory = {
        // //                         id = namespace;
        // //                         name = "Auto-generated category " # namespace;
        // //                         description = "Automatically created category";
        // //                         parentId = ?getParentId(namespace);
        // //                     };
        // //                     let created = await categoryRepo.createCategory(newCategory);
        // //                     if (created) {
        // //                         Debug.print("NamespaceCategoryMapper: Created new category: " # namespace);
        // //                         matchedCategories := ArrayUtils.pushToArray(namespace, matchedCategories);
        // //                     } else {
        // //                         Debug.print("NamespaceCategoryMapper: Failed to create category: " # namespace);
        // //                     };
        // //                 };
        // //             };
        // //         };
        // //         currentNamespace := getParentId(currentNamespace);
        // //     };

        // //     Array.reverse(matchedCategories);
        // // };
        // public func mapNamespaceToCategories(namespace : Text) : async [NamespaceCategoryMapping.CategoryId] {
        //     let parts = Text.split(namespace, #char '.');
        //     var allCategories : [NamespaceCategoryMapping.CategoryId] = [];

        //     for (part in parts.vals()) {
        //         let categories = await repository.getCategories(part);
        //         allCategories := Array.append(allCategories, categories);
        //     };

        //     Array.removeDuplicates(allCategories, Text.equal);
        // };

        // public func findMostRelevantCategories(namespace : Text, maxCategories : Nat) : async [NamespaceCategoryMapping.CategoryId] {
        //     let allMatchedCategories = await mapNamespaceToCategories(namespace);
        //     let scoredCategories = Array.map(allMatchedCategories, func(category : NamespaceCategoryMapping.CategoryId) : (NamespaceCategoryMapping.CategoryId, Nat) { (category, await calculateRelevanceScore(namespace, category)) });

        //     let sortedCategories = Array.sort(
        //         scoredCategories,
        //         func(a : (NamespaceCategoryMapping.CategoryId, Nat), b : (NamespaceCategoryMapping.CategoryId, Nat)) : {
        //             #less;
        //             #equal;
        //             #greater;
        //         } {
        //             Nat.compare(b.1, a.1);
        //         },
        //     );

        //     Array.map(Array.slice(sortedCategories, 0, Nat.min(maxCategories, sortedCategories.size())), func(item : (NamespaceCategoryMapping.CategoryId, Nat)) : NamespaceCategoryMapping.CategoryId { item.0 });
        // };

        // private func calculateRelevanceScore(namespace : Text, categoryId : NamespaceCategoryMapping.CategoryId) : async Nat {
        //     let parts = Text.split(namespace, #char '.');
        //     let namespaces = await repository.getNamespaces(categoryId);
        //     var score = 0;

        //     for (part in parts.vals()) {
        //         if (Array.find(namespaces, func(ns : Text) : Bool { ns == part }) != null) {
        //             score += 1;
        //         };
        //     };

        //     score;
        // };

        private func getParentId(id : Text) : Text {
            let partsArray = Iter.toArray(Text.split(id, #char '.'));

            if (partsArray.size() <= 1) {
                return "";
            };

            let parentParts = Buffer.Buffer<Text>(partsArray.size() - 1);
            for (i in Iter.range(0, partsArray.size() - 2)) {
                parentParts.add(partsArray[i]);
            };

            Text.join(".", parentParts.vals());
        };

        // This method can be useful for getting all parent categories
        public func getParentCategories(categoryId : Category.CategoryId) : async [Category.CategoryId] {
            var parentCategories : [Category.CategoryId] = [];
            var currentCategoryId = categoryId;

            while (Text.size(currentCategoryId) > 0) {
                currentCategoryId := getParentId(currentCategoryId);
                if (Text.size(currentCategoryId) > 0) {
                    parentCategories := ArrayUtils.pushToArray(currentCategoryId, parentCategories);
                };
            };

            parentCategories;
        };
    };
};
