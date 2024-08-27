import Result "mo:base/Result";
import Category "../entities/Category";
import CategoryRepositoryImpl "../../data/repositories/CategoryRepositoryImpl";

module {
    public class ManageCategoriesUseCase(categoryRepo : CategoryRepositoryImpl.CategoryRepositoryImpl) {
        public func createCategory(id : Category.CategoryId, name : Text, description : Text, parentId : ?Category.CategoryId) : async Result.Result<Category.Category, Text> {
            let newCategory = await Category.createCategory(id, name, description, parentId);
            if (categoryRepo.createCategory(newCategory)) {
                #ok(newCategory);
            } else {
                #err("Failed to create category");
            };
        };

        public func getCategory(id : Category.CategoryId) : Result.Result<Category.Category, Text> {
            switch (categoryRepo.getCategory(id)) {
                case (?category) { #ok(category) };
                case (null) { #err("Category not found") };
            };
        };

        public func updateCategory(category : Category.Category) : Result.Result<(), Text> {
            if (categoryRepo.updateCategory(category)) {
                #ok(());
            } else {
                #err("Failed to update category");
            };
        };

        public func listCategories() : [Category.Category] {
            categoryRepo.listCategories();
        };
    };
};
