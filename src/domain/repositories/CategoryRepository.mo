import Category "../entities/Category";

module {
    public type CategoryRepository = actor {
        createCategory : (Category.Category) -> async Bool;
        getCategory : (Category.CategoryId) -> async ?Category.Category;
        updateCategory : (Category.Category) -> async Bool;
        listCategories : () -> async [Category.Category];
    };
};
