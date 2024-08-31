import CategoryData "./CategoryData";

module {
    public let engineeringTechnology : CategoryData.CategoryData = {
        id = "2";
        name = "Engineering and technology";
        description = "Application of scientific and mathematical principles to practical ends";
        parentId = null;
        subCategories = [
            {
                id = "2.1";
                name = "Civil engineering";
                description = "Design and construction of the built environment";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.2";
                name = "Electrical engineering, electronic engineering, information engineering";
                description = "Study and application of electricity, electronics, and information technologies";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.3";
                name = "Mechanical engineering";
                description = "Design, manufacturing, and maintenance of mechanical systems";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.4";
                name = "Chemical engineering";
                description = "Application of chemical, physical, and biological sciences to process engineering";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.5";
                name = "Materials engineering";
                description = "Design and discovery of new materials";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.6";
                name = "Medical engineering";
                description = "Application of engineering principles to healthcare and medicine";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.7";
                name = "Environmental engineering";
                description = "Engineering solutions for environmental protection and improvement";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.8";
                name = "Environmental biotechnology";
                description = "Use of biological systems for environmental applications";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.9";
                name = "Industrial biotechnology";
                description = "Application of biotechnology for industrial purposes";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.10";
                name = "Nano technology";
                description = "Manipulation of matter on an atomic, molecular, and supramolecular scale";
                parentId = ?"2";
                subCategories = [];
            },
            {
                id = "2.11";
                name = "Other engineering and technologies";
                description = "Engineering and technology fields not classified elsewhere";
                parentId = ?"2";
                subCategories = [];
            },
        ];
    };
};
