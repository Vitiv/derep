import Category "../entities/Category";
import HashMap "mo:base/HashMap";

module {
    public type CategoryRepository = {
        var categories : HashMap.HashMap<Category.CategoryId, Category.Category>;
        createCategory : (Category.Category) -> async Bool;
        getCategory : (Category.CategoryId) -> async ?Category.Category;
        updateCategory : (Category.Category) -> async Bool;
        listCategories : () -> async [Category.Category];
        getCategoriesByParent : (?Category.CategoryId) -> async [Category.Category];
        deleteCategory : (Category.CategoryId) -> async Bool;
        clearAllCategories : () -> async Bool;
        ensureCategoryHierarchy : (Text) -> async ();
    };
};
