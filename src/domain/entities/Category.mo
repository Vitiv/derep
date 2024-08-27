module {
    public type CategoryId = Text;

    public type Category = {
        id : CategoryId;
        name : Text;
        description : Text;
        parentId : ?CategoryId;
    };

    public func createCategory(id : CategoryId, name : Text, description : Text, parentId : ?CategoryId) : async Category {
        {
            id = id;
            name = name;
            description = description;
            parentId = parentId;
        };
    };
};
