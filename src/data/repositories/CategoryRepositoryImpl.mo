import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Array "mo:base/Array";

import Category "../../domain/entities/Category";

module {
    public class CategoryRepositoryImpl() {
        private var categories = HashMap.HashMap<Category.CategoryId, Category.Category>(10, Text.equal, Text.hash);

        public func createCategory(category : Category.Category) : async Bool {
            switch (categories.get(category.id)) {
                case (?_) {
                    Debug.print("CategoryRepositoryImpl.createCategory: Category already exists: " # category.id);
                    false;
                };
                case null {
                    categories.put(category.id, category);
                    Debug.print("CategoryRepositoryImpl.createCategory: Category created: " # category.id);
                    true;
                };
            };
        };

        public func getCategory(id : Category.CategoryId) : async ?Category.Category {
            let result = categories.get(id);
            switch (result) {
                case (?category) {
                    Debug.print("CategoryRepositoryImpl.getCategory: Found category: " # debug_show (category));
                };
                case (null) {
                    Debug.print("CategoryRepositoryImpl.getCategory: Category not found for id: " # id);
                };
            };
            result;
        };

        public func updateCategory(category : Category.Category) : async Bool {
            switch (categories.get(category.id)) {
                case null { false }; // Category doesn't exist
                case (?_) {
                    categories.put(category.id, category);
                    true;
                };
            };
        };

        public func listCategories() : async [Category.Category] {
            Iter.toArray(categories.vals());
        };

        public func getCategoriesByParent(parentId : ?Category.CategoryId) : async [Category.Category] {
            Iter.toArray(
                Iter.filter(
                    categories.vals(),
                    func(category : Category.Category) : Bool {
                        category.parentId == parentId;
                    },
                )
            );
        };

        public func clearAllCategories() : async Bool {
            categories := HashMap.HashMap<Category.CategoryId, Category.Category>(10, Text.equal, Text.hash);
            true;
        };

        public func deleteCategory(id : Category.CategoryId) : async Bool {
            switch (categories.remove(id)) {
                case (null) { false };
                case (?_) { true };
            };
        };

        public func ensureCategoryHierarchy(categoryId : Text) : async () {
            var currentId = categoryId;
            while (currentId != "") {
                switch (await getCategory(currentId)) {
                    case (null) {
                        let newCategory = {
                            id = currentId;
                            name = "Auto-generated category " # currentId;
                            description = "Automatically created category";
                            parentId = ?getParentId(currentId);
                        };
                        ignore await createCategory(newCategory);
                    };
                    case (?_) {};
                };
                currentId := getParentId(currentId);
            };
        };

        private func getParentId(id : Text) : Text {
            let parts = Iter.toArray(Text.split(id, #char '.'));
            if (parts.size() <= 1) {
                return "";
            } else {
                let parentParts = Array.tabulate<Text>(parts.size() - 1, func(i : Nat) : Text { parts[i] });
                return Text.join(".", parentParts.vals());
            };
        };
    };
};
