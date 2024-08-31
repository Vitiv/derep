import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

import Category "../entities/Category";
import CategoryRepository "../repositories/CategoryRepository";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class NamespaceCategoryMapper(categoryRepo : CategoryRepository.CategoryRepository) {
        public func mapNamespaceToCategories(namespace : Text) : async [Category.CategoryId] {
            var matchedCategories : [Category.CategoryId] = [];
            var currentNamespace = namespace;

            while (Text.size(currentNamespace) > 0) {
                switch (await categoryRepo.getCategory(currentNamespace)) {
                    case (?category) {
                        matchedCategories := ArrayUtils.pushToArray(category.id, matchedCategories);
                    };
                    case (null) {
                        if (currentNamespace == namespace) {
                            // Create new category if it doesn't exist
                            let newCategory = {
                                id = namespace;
                                name = "Auto-generated category " # namespace;
                                description = "Automatically created category";
                                parentId = ?getParentId(namespace);
                            };
                            let created = await categoryRepo.createCategory(newCategory);
                            if (created) {
                                Debug.print("NamespaceCategoryMapper: Created new category: " # namespace);
                                matchedCategories := ArrayUtils.pushToArray(namespace, matchedCategories);
                            } else {
                                Debug.print("NamespaceCategoryMapper: Failed to create category: " # namespace);
                            };
                        };
                    };
                };
                currentNamespace := getParentId(currentNamespace);
            };

            Array.reverse(matchedCategories);
        };

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
