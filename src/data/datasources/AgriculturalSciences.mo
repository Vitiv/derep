import CategoryData "./CategoryData";

module {
    public let agriculturalSciences : CategoryData.CategoryData = {
        id = "4";
        name = "Agricultural sciences";
        description = "Sciences dealing with food and fibre production and processing";
        parentId = null;
        subCategories = [
            {
                id = "4.1";
                name = "Agriculture, forestry, and fisheries";
                description = "Study of crop production, forestry, and aquatic resources";
                parentId = ?"4";
                subCategories = [];
            },
            {
                id = "4.2";
                name = "Animal and dairy science";
                description = "Study of animals and animal products";
                parentId = ?"4";
                subCategories = [];
            },
            {
                id = "4.3";
                name = "Veterinary science";
                description = "Study of animal health and diseases";
                parentId = ?"4";
                subCategories = [];
            },
            {
                id = "4.4";
                name = "Agricultural biotechnology";
                description = "Application of biotechnology to agriculture";
                parentId = ?"4";
                subCategories = [];
            },
            {
                id = "4.5";
                name = "Other agricultural sciences";
                description = "Agricultural sciences not classified elsewhere";
                parentId = ?"4";
                subCategories = [];
            },
        ];
    };
};
