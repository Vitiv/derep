import NamespaceCategoryMapper "../services/NamespaceCategoryMapper";
import DocumentClassifier "../services/DocumentClassifier";
import NamespaceCategoryMappingRepository "../repositories/NamespaceCategoryMappingRepository";
import Category "../entities/Category";
import Option "mo:base/Option";

module {
    public class DetermineCategoriesUseCase(
        namespaceCategoryMapper : NamespaceCategoryMapper.NamespaceCategoryMapper,
        documentClassifier : DocumentClassifier.DocumentClassifier,
        namespaceMappingRepo : NamespaceCategoryMappingRepository.NamespaceCategoryMappingRepository,
    ) {
        public func execute(namespace : Text, documentUrl : ?Text) : async [Category.CategoryId] {
            var categories = await namespaceCategoryMapper.mapNamespaceToCategories(namespace, documentUrl, null);

            if (categories.size() == 0 and documentUrl != null) {
                categories := await documentClassifier.classifyDocument(Option.get(documentUrl, ""));
            };

            if (categories.size() == 0) {
                categories := await namespaceMappingRepo.getCategoriesForNamespace(namespace);
            };

            categories;
        };
    };
};
