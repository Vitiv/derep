import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import NamespaceDictionary "../../data/datasources/NamespaceDictionary";

module {
    public class DocumentClassifier() {
        private let keywordCategories = NamespaceDictionary.initialMappings;

        public func classifyDocument(documentUrl : Text) : async [Text] {
            Debug.print("Classifying document: " # documentUrl);

            let categoriesBuffer = Buffer.Buffer<Text>(0);

            for ((keyword, category) in keywordCategories.vals()) {
                if (Text.contains(documentUrl, #text keyword)) {
                    if (not Buffer.contains<Text>(categoriesBuffer, category, Text.equal)) {
                        categoriesBuffer.add(category);
                    };
                };
            };

            let uniqueCategories = Buffer.toArray(categoriesBuffer);

            if (uniqueCategories.size() == 0) {
                ["1.2.2"] // Default category if no matches found
            } else {
                uniqueCategories;
            };
        };
    };
};
