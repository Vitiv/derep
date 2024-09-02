import CategoryData "./CategoryData";

module {
    public let humanities : CategoryData.CategoryData = {
        id = "6";
        name = "Humanities";
        description = "Study of human culture and expression";
        parentId = null;
        subCategories = [
            {
                id = "6.1";
                name = "History and archaeology";
                description = "Study of past events and material remains";
                parentId = ?"6";
                subCategories = [];
            },
            {
                id = "6.2";
                name = "Languages and literature";
                description = "Study of language systems and literary works";
                parentId = ?"6";
                subCategories = [];
            },
            {
                id = "6.3";
                name = "Philosophy, ethics and religion";
                description = "Study of fundamental questions about existence, knowledge, values, reason, mind, and language";
                parentId = ?"6";
                subCategories = [];
            },
            {
                id = "6.4";
                name = "Arts (arts, history of arts, performing arts, music)";
                description = "Study of creative and performing arts";
                parentId = ?"6";
                subCategories = [];
            },
            {
                id = "6.5";
                name = "Other humanities";
                description = "Humanities not classified elsewhere";
                parentId = ?"6";
                subCategories = [];
            },
        ];
    };
};
