import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Category "../../domain/entities/Category";
import ArrayUtils "../../../utils/ArrayUtils";

module {
    public class NamespaceCategoryMappingRepositoryImpl() {
        private var mappings = HashMap.HashMap<Text, [Category.CategoryId]>(10, Text.equal, Text.hash);
        private var reverseMappings = HashMap.HashMap<Category.CategoryId, [Text]>(10, Text.equal, Text.hash);

        public func getCategoriesForNamespace(namespace : Text) : async [Category.CategoryId] {
            switch (mappings.get(namespace)) {
                case (?categories) categories;
                case null [];
            };
        };

        public func addNamespaceCategoryMapping(namespace : Text, categoryId : Category.CategoryId) : async Bool {
            switch (mappings.get(namespace)) {
                case (?categories) {
                    let catId = Array.find<Category.CategoryId>(categories, func(id) { id == categoryId });
                    switch (catId) {
                        case (?cId) mappings.put(namespace, ArrayUtils.pushToArray<Category.CategoryId>(cId, categories));
                        case null {};
                    };
                };
                case null {
                    mappings.put(namespace, [categoryId]);
                };
            };

            switch (reverseMappings.get(categoryId)) {
                case (?namespaces) {
                    let names = Array.find<Text>(namespaces, func(id) { id == namespace });
                    switch (names) {
                        case (?n) mappings.put(categoryId, ArrayUtils.pushToArray<Category.CategoryId>(n, namespaces));
                        case null {};
                    };
                };
                case null {
                    reverseMappings.put(categoryId, [namespace]);
                };
            };

            true;
        };

        public func getNamespacesForCategory(categoryId : Category.CategoryId) : async [Text] {
            switch (reverseMappings.get(categoryId)) {
                case (?namespaces) namespaces;
                case null [];
            };
        };

        public func removeNamespaceCategoryMapping(namespace : Text, categoryId : Category.CategoryId) : async Bool {
            switch (mappings.get(namespace)) {
                case (?categories) {
                    let updatedCategories = Array.filter<Category.CategoryId>(categories, func(id) { id != categoryId });
                    if (updatedCategories.size() == 0) {
                        mappings.delete(namespace);
                    } else {
                        mappings.put(namespace, updatedCategories);
                    };
                    true;
                };
                case null false;
            };
        };

        public func getAllMappings() : async [(Text, [Category.CategoryId])] {
            Iter.toArray(mappings.entries());
        };

        public func initializeMappings(initialMappings : [(Text, Category.CategoryId)]) : async () {
            for ((namespace, categoryId) in initialMappings.vals()) {
                ignore await addNamespaceCategoryMapping(namespace, categoryId);
            };
        };
    };
};
