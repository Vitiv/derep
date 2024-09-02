import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";

module {
    public type Namespace = Text;
    public type CategoryId = Text;

    public type NamespaceCategoryMapping = {
        namespaceToCategories : TrieSet.Set<CategoryId>;
        categoryToNamespaces : TrieSet.Set<Namespace>;
    };

    public func createMapping() : NamespaceCategoryMapping {
        {
            namespaceToCategories = TrieSet.empty<CategoryId>();
            categoryToNamespaces = TrieSet.empty<Namespace>();
        };
    };

    public func addMapping(mapping : NamespaceCategoryMapping, namespace : Namespace, categoryId : CategoryId) : NamespaceCategoryMapping {
        {
            namespaceToCategories = TrieSet.put<CategoryId>(mapping.namespaceToCategories, categoryId, Text.hash(categoryId), Text.equal);
            categoryToNamespaces = TrieSet.put<Namespace>(mapping.categoryToNamespaces, namespace, Text.hash(namespace), Text.equal);
        };
    };
};
