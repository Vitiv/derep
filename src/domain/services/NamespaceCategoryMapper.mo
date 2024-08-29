import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Category "../entities/Category";
import CategoryRepository "../repositories/CategoryRepository";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class NamespaceCategoryMapper(categoryRepo : CategoryRepository.CategoryRepository) {
        public func mapNamespaceToCategories(namespace : Text) : async [Category.CategoryId] {
            let parts = Text.split(namespace, #char '.');
            let categories = await categoryRepo.listCategories();
            var matchedCategories : [Category.CategoryId] = [];

            for (part in Iter.toArray(parts).vals()) {
                let matchingCategories = Array.filter(
                    categories,
                    func(category : Category.Category) : Bool {
                        Text.contains(category.name, #text part);
                    },
                );

                for (category in matchingCategories.vals()) {
                    if (not contains(matchedCategories, category.id)) {
                        matchedCategories := ArrayUtils.pushToArray(category.id, matchedCategories);
                        // Add parent categories
                        let parentCategories = await getParentCategories(category.id);
                        for (parentId in parentCategories.vals()) {
                            if (not contains(matchedCategories, parentId)) {
                                matchedCategories := ArrayUtils.pushToArray(parentId, matchedCategories);
                            };
                        };
                    };
                };
            };

            matchedCategories;
        };

        private func contains(arr : [Category.CategoryId], item : Category.CategoryId) : Bool {
            for (element in arr.vals()) {
                if (Text.equal(element, item)) {
                    return true;
                };
            };
            false;
        };

        public func getParentCategories(categoryId : Category.CategoryId) : async [Category.CategoryId] {
            var parentCategories : [Category.CategoryId] = [];
            var currentCategoryId = categoryId;

            label a while (true) {
                switch (await categoryRepo.getCategory(currentCategoryId)) {
                    case null { break a };
                    case (?category) {
                        switch (category.parentId) {
                            case null { break a };
                            case (?parentId) {
                                parentCategories := ArrayUtils.pushToArray(parentId, parentCategories);
                                currentCategoryId := parentId;
                            };
                        };
                    };
                };
            };

            parentCategories;
        };
    };
};
