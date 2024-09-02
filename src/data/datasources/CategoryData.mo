module {
    public type CategoryData = {
        id : Text;
        name : Text;
        description : Text;
        parentId : ?Text;
        subCategories : [CategoryData];
    };
};
