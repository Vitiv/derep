import CategoryData "./CategoryData";

module {
    public let medicalHealthSciences : CategoryData.CategoryData = {
        id = "3";
        name = "Medical and health sciences";
        description = "Study of human health and diseases";
        parentId = null;
        subCategories = [
            {
                id = "3.1";
                name = "Basic medicine";
                description = "Fundamental aspects of medicine and medical sciences";
                parentId = ?"3";
                subCategories = [];
            },
            {
                id = "3.2";
                name = "Clinical medicine";
                description = "Diagnosis, treatment, and prevention of disease";
                parentId = ?"3";
                subCategories = [];
            },
            {
                id = "3.3";
                name = "Health sciences";
                description = "Study of health, healthcare, and health systems";
                parentId = ?"3";
                subCategories = [];
            },
            {
                id = "3.4";
                name = "Health biotechnology";
                description = "Application of biotechnology to healthcare";
                parentId = ?"3";
                subCategories = [];
            },
            {
                id = "3.5";
                name = "Other medical sciences";
                description = "Medical sciences not classified elsewhere";
                parentId = ?"3";
                subCategories = [];
            },
        ];
    };
};
