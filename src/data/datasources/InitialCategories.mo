import Category "../../domain/entities/Category";
import ArrayUtils "../../../utils/ArrayUtils";
import CategoryData "./CategoryData";
import NaturalSciences "./NaturalSciences";
import EngineeringTechnology "./EngineeringTechnology";
import MedicalHealthSciences "./MedicalHealthSciences";
import AgriculturalSciences "./AgriculturalSciences";
import SocialSciences "./SocialSciences";
import Humanities "./Humanities";

module {
    public type CategoryData = {
        id : Text;
        name : Text;
        description : Text;
        parentId : ?Text;
        subCategories : [CategoryData];
    };

    public let initialCategories : [CategoryData.CategoryData] = [
        NaturalSciences.naturalSciences,
        EngineeringTechnology.engineeringTechnology,
        MedicalHealthSciences.medicalHealthSciences,
        AgriculturalSciences.agriculturalSciences,
        SocialSciences.socialSciences,
        Humanities.humanities,
    ];
    public func flattenCategories(categories : [CategoryData]) : [Category.Category] {
        var flatList : [Category.Category] = [];

        func flatten(category : CategoryData) {
            let cat : Category.Category = {
                id = category.id;
                name = category.name;
                description = category.description;
                parentId = category.parentId;
            };
            flatList := ArrayUtils.pushToArray(cat, flatList);

            for (subCat in category.subCategories.vals()) {
                flatten(subCat);
            };
        };

        for (category in categories.vals()) {
            flatten(category);
        };

        flatList;
    };
};
