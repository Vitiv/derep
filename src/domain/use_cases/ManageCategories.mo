import Result "mo:base/Result";
import Category "../entities/Category";
import CategoryRepository "../repositories/CategoryRepository";

module {
    public class ManageCategoriesUseCase(categoryRepo : CategoryRepository.CategoryRepository) {
        public func createCategory(id : Category.CategoryId, name : Text, description : Text, parentId : ?Category.CategoryId) : async Result.Result<Category.Category, Text> {
            let newCategory = await Category.createCategory(id, name, description, parentId);
            switch (await categoryRepo.createCategory(newCategory)) {
                case (true) { #ok(newCategory) };
                case (false) { #err("Failed to create category") };
            };
        };

        public func getCategory(id : Category.CategoryId) : async Result.Result<Category.Category, Text> {
            switch (await categoryRepo.getCategory(id)) {
                case (?category) { #ok(category) };
                case (null) { #err("Category not found") };
            };
        };

        public func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
            switch (await categoryRepo.updateCategory(category)) {
                case (true) { #ok(()) };
                case (false) { #err("Failed to update category") };
            };
        };

        public func listCategories() : async [Category.Category] {
            await categoryRepo.listCategories();
        };
    };
};
