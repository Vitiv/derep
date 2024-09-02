import CategoryData "CategoryData";

module {
    public let naturalSciences : CategoryData.CategoryData = {
        id = "1";
        name = "Natural sciences";
        description = "Field of science dealing with natural phenomena";
        parentId = null;
        subCategories = [
            {
                id = "1.1";
                name = "Mathematics";
                description = "Study of quantity, structure, space, and change";
                parentId = ?"1";
                subCategories = [];
            },
            {
                id = "1.2";
                name = "Computer and information sciences";
                description = "Study of computation, information processing, and systems";
                parentId = ?"1";
                subCategories = [
                    {
                        id = "1.2.1";
                        name = "aVa projects";
                        description = "Projects related to aVa";
                        parentId = ?"1.2";
                        subCategories = [];
                    },
                    {
                        id = "1.2.2";
                        name = "Internet Computer";
                        description = "Topics related to Internet Computer";
                        parentId = ?"1.2";
                        subCategories = [];
                    },
                    {
                        id = "1.2.3";
                        name = "Programming Languages";
                        description = "Study and application of programming languages";
                        parentId = ?"1.2";
                        subCategories = [
                            {
                                id = "1.2.3.1";
                                name = "Javascript";
                                description = "JavaScript programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.2";
                                name = "Rust";
                                description = "Rust programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.3";
                                name = "Java";
                                description = "Java programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.4";
                                name = "Motoko";
                                description = "Motoko programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.5";
                                name = "Python";
                                description = "Python programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.6";
                                name = "C++";
                                description = "C++ programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                            {
                                id = "1.2.3.7";
                                name = "Solidity";
                                description = "Solidity programming language";
                                parentId = ?"1.2.3";
                                subCategories = [];
                            },
                        ];
                    },
                ];
            },
            {
                id = "1.3";
                name = "Physical sciences";
                description = "Study of non-living systems";
                parentId = ?"1";
                subCategories = [];
            },
            {
                id = "1.4";
                name = "Chemical sciences";
                description = "Study of composition, structure, properties and change of matter";
                parentId = ?"1";
                subCategories = [];
            },
            {
                id = "1.5";
                name = "Earth and related environmental sciences";
                description = "Study of Earth's systems and environment";
                parentId = ?"1";
                subCategories = [];
            },
            {
                id = "1.6";
                name = "Biological sciences";
                description = "Study of life and living organisms";
                parentId = ?"1";
                subCategories = [];
            },
            {
                id = "1.7";
                name = "Other natural sciences";
                description = "Natural sciences not classified elsewhere";
                parentId = ?"1";
                subCategories = [];
            },
        ];
    };
};
