import CategoryData "./CategoryData";

module {
    public let socialSciences : CategoryData.CategoryData = {
        id = "5";
        name = "Social sciences";
        description = "Study of human society and social relationships";
        parentId = null;
        subCategories = [
            {
                id = "5.1";
                name = "Psychology";
                description = "Study of mind and behavior";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.2";
                name = "Economics and business";
                description = "Study of production, distribution, and consumption of goods and services";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.3";
                name = "Educational sciences";
                description = "Study of learning and teaching processes";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.4";
                name = "Sociology";
                description = "Study of society and social behavior";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.5";
                name = "Law";
                description = "Study of rules and regulations governing society";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.6";
                name = "Political science";
                description = "Study of governments, public policies and political processes";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.7";
                name = "Social and economic geography";
                description = "Study of spatial aspects of human organization and activities";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.8";
                name = "Media and communications";
                description = "Study of mass communication and its effects on society";
                parentId = ?"5";
                subCategories = [];
            },
            {
                id = "5.9";
                name = "Other social sciences";
                description = "Social sciences not classified elsewhere";
                parentId = ?"5";
                subCategories = [];
            },
        ];
    };
};
