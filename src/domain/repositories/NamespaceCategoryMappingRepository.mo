import Category "../entities/Category";
import HashMap "mo:base/HashMap";

module {
    public type NamespaceCategoryMappingRepository = {
        var mappings : HashMap.HashMap<Text, [Category.CategoryId]>;
        var reverseMappings : HashMap.HashMap<Category.CategoryId, [Text]>;
        getCategoriesForNamespace : (namespace : Text) -> async [Category.CategoryId];
        addNamespaceCategoryMapping : (namespace : Text, categoryId : Category.CategoryId) -> async Bool;
        removeNamespaceCategoryMapping : (namespace : Text, categoryId : Category.CategoryId) -> async Bool;
        getNamespacesForCategory : (Category.CategoryId) -> async [Text];
    };
};
