import Category "../../domain/entities/Category";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

module {
    public class CategoryRepositoryImpl() {
        private var categories = HashMap.HashMap<Category.CategoryId, Category.Category>(10, Text.equal, Text.hash);

        public func createCategory(category : Category.Category) : Bool {
            switch (categories.get(category.id)) {
                case (?_) { false }; // Category already exists
                case null {
                    categories.put(category.id, category);
                    true;
                };
            };
        };

        public func getCategory(id : Category.CategoryId) : ?Category.Category {
            categories.get(id);
        };

        public func updateCategory(category : Category.Category) : Bool {
            switch (categories.get(category.id)) {
                case null { false }; // Category doesn't exist
                case (?_) {
                    categories.put(category.id, category);
                    true;
                };
            };
        };

        public func listCategories() : [Category.Category] {
            Iter.toArray(categories.vals());
        };

        public func getCategoriesByParent(parentId : ?Category.CategoryId) : [Category.Category] {
            Iter.toArray(
                Iter.filter(
                    categories.vals(),
                    func(category : Category.Category) : Bool {
                        category.parentId == parentId;
                    },
                )
            );
        };
    };
};
