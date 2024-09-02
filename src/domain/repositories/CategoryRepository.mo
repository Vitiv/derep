import Category "../entities/Category";

module {
    public type CategoryRepository = {
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
