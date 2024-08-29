import Category "../../domain/entities/Category";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

module {
    public class CategoryRepositoryImpl() {
        private var categories = HashMap.HashMap<Category.CategoryId, Category.Category>(10, Text.equal, Text.hash);

        public func createCategory(category : Category.Category) : async Bool {
            switch (categories.get(category.id)) {
                case (?_) { false }; // Category already exists
                case null {
                    categories.put(category.id, category);
                    true;
                };
            };
        };

        public func getCategory(id : Category.CategoryId) : async ?Category.Category {
            categories.get(id);
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
    };
};
