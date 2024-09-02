import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Category "../entities/Category";
import CategoryRepositoryImpl "../../data/repositories/CategoryRepositoryImpl";

module {
    public class ManageCategoriesUseCase(categoryRepo : CategoryRepositoryImpl.CategoryRepositoryImpl) {
        public func createCategory(id : Category.CategoryId, name : Text, description : Text, parentId : ?Category.CategoryId) : async Result.Result<Category.Category, Text> {
            let existingCategory = await categoryRepo.getCategory(id);

            switch (existingCategory) {
                case (?category) {
                    Debug.print("Category already exists: " # id);
                    return #ok(category);
                };
                case (null) {
                    let newCategory = {
                        id = id;
                        name = name;
                        description = description;
                        parentId = parentId;
                    };

                    if (await categoryRepo.createCategory(newCategory)) {
                        #ok(newCategory);
                    } else {
                        #err("Failed to create category");
                    };
                };
            };
        };

        public func getCategory(id : Category.CategoryId) : async Result.Result<Category.Category, Text> {
            switch (await categoryRepo.getCategory(id)) {
                case (?category) { #ok(category) };
                case (null) { #err("Category not found") };
            };
        };

        public func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
            if (await categoryRepo.updateCategory(category)) {
                #ok(());
            } else {
                #err("Failed to update category");
            };
        };

        public func listCategories() : async [Category.Category] {
            await categoryRepo.listCategories();
        };
    };
};
