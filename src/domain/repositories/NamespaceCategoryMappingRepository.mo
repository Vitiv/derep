import Category "../entities/Category";

module {
    public type NamespaceCategoryMappingRepository = {
        getCategoriesForNamespace : (namespace : Text) -> async [Category.CategoryId];
        addNamespaceCategoryMapping : (namespace : Text, categoryId : Category.CategoryId) -> async Bool;
        removeNamespaceCategoryMapping : (namespace : Text, categoryId : Category.CategoryId) -> async Bool;
        getNamespacesForCategory : (Category.CategoryId) -> async [Text];
    };
};
