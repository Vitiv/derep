import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import Nat32 "mo:base/Nat32";
import Buffer "mo:base/Buffer";
import T "../../src/domain/entities/Types";
import User "../../src/domain/entities/User";
import Category "../../src/domain/entities/Category";
import Reputation "../../src/domain/entities/Reputation";

actor class MockedReputationActorTest() {
    // Mock ReputationActor
    class MockReputationActor() {
        var categories = HashMap.HashMap<Text, Category.Category>(10, Text.equal, Text.hash);

        // Helper function to create a combined hash for (Principal, Text) pair
        func hashPrincipalText(principal : Principal, text : Text) : Hash.Hash {
            let principalHash = Principal.hash(principal);
            let textHash = Text.hash(text);
            // Combine hashes using bitwise XOR
            principalHash ^ textHash;
        };

        var reputations = HashMap.HashMap<(Principal, Text), Reputation.Reputation>(
            10,
            func(x, y) { x.0 == y.0 and x.1 == y.1 },
            func(key : (Principal, Text)) : Hash.Hash {
                hashPrincipalText(key.0, key.1);
            },
        );

        public func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
            let category : Category.Category = {
                id = id;
                name = name;
                description = description;
                parentId = parentId;
            };
            categories.put(id, category);
            #ok(category);
        };

        public func getCategory(id : Text) : async Result.Result<Category.Category, Text> {
            switch (categories.get(id)) {
                case (?category) { #ok(category) };
                case (null) { #err("Category not found") };
            };
        };

        public func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
            categories.put(category.id, category);
            #ok(());
        };

        public func listCategories() : async [Category.Category] {
            Array.map<(Text, Category.Category), Category.Category>(Iter.toArray(categories.entries()), func(entry) { entry.1 });
        };

        public func updateReputation(userId : Principal, categoryId : Text, scoreChange : Int) : async Result.Result<(), Text> {
            let key = (userId, categoryId);
            let currentReputation = switch (reputations.get(key)) {
                case (?rep) { rep };
                case (null) {
                    {
                        userId = userId;
                        categoryId = categoryId;
                        score = 0;
                        lastUpdated = Time.now();
                    };
                };
            };
            let newReputation = {
                userId = currentReputation.userId;
                categoryId = currentReputation.categoryId;
                score = currentReputation.score + scoreChange;
                lastUpdated = Time.now();
            };
            reputations.put(key, newReputation);
            #ok(());
        };

        public func getUserReputation(userId : Principal, categoryId : Text) : async Result.Result<Reputation.Reputation, Text> {
            switch (reputations.get((userId, categoryId))) {
                case (?reputation) { #ok(reputation) };
                case (null) { #err("Reputation not found") };
            };
        };

        public func getUserReputations(userId : User.UserId) : async Result.Result<[Reputation.Reputation], Text> {
            let userReputations = Buffer.Buffer<Reputation.Reputation>(0);

            for (((uId, _), reputation) in reputations.entries()) {
                if (Principal.equal(uId, userId)) {
                    userReputations.add(reputation);
                };
            };

            if (userReputations.size() == 0) {
                #err("No reputations found for the user");
            } else {
                #ok(Buffer.toArray(userReputations));
            };
        };
        public func reset() : async () {
            categories := HashMap.HashMap<Text, Category.Category>(10, Text.equal, Text.hash);
            reputations := HashMap.HashMap<(Principal, Text), Reputation.Reputation>(
                10,
                func(x, y) { x.0 == y.0 and x.1 == y.1 },
                func(key : (Principal, Text)) : Hash.Hash {
                    hashPrincipalText(key.0, key.1);
                },
            );
        };
    };

    var mockActor = MockReputationActor();

    // Helper function to create a test principal
    func createTestPrincipal(n : Nat) : Principal {
        Principal.fromText("aaaaa-aa");
    };

    // Reset function to clear state between tests
    public func reset() : async () {
        Debug.print("Running reset");
        await mockActor.reset();
    };

    // Test functions
    public func testCreateCategory() : async () {
        Debug.print("Running testCreateCategory");
        await reset();
        Debug.print("Running createCategory");
        let result = await mockActor.createCategory("test-category", "Test Category", "This is a test category", null);
        switch (result) {
            case (#ok(category)) {
                Debug.print("result createCategory: " # debug_show (result));
                assert (category.id == "test-category");
                assert (category.name == "Test Category");
                assert (category.description == "This is a test category");
                assert (category.parentId == null);
            };
            case (#err(e)) {
                Debug.print("result createCategory - error" # debug_show (e));
                assert (false); // This should not happen
            };
        };
    };

    public func testGetCategory() : async () {
        Debug.print("Running testGetCategory");

        await reset();
        ignore await mockActor.createCategory("test-category", "Test Category", "This is a test category", null);
        let result = await mockActor.getCategory("test-category");
        switch (result) {
            case (#ok(category)) {
                Debug.print("result getCategory: " # debug_show (result));

                assert (category.id == "test-category");
                assert (category.name == "Test Category");
                assert (category.description == "This is a test category");
                assert (category.parentId == null);
            };
            case (#err(e)) {
                Debug.print("result getCategory: " # debug_show (e));

                assert (false); // This should not happen
            };
        };
    };

    public func testUpdateReputation() : async () {
        Debug.print("Running testUpdateReputation");

        await reset();
        let testUser = createTestPrincipal(5);
        let result = await mockActor.updateReputation(testUser, "test-category", 100);
        assert (Result.isOk(result));

        let reputationResult = await mockActor.getUserReputation(testUser, "test-category");
        switch (reputationResult) {
            case (#ok(reputation)) {
                Debug.print("result updateReputation: " # debug_show (reputationResult));

                assert (reputation.userId == testUser);
                assert (reputation.categoryId == "test-category");
                assert (reputation.score == 100);
            };
            case (#err(e)) {
                Debug.print("result updateReputation: " # debug_show (e));

                assert (false); // This should not happen
            };
        };

        // Second update
        let result2 = await mockActor.updateReputation(testUser, "test-category", 100);
        assert (Result.isOk(result2));

        let reputationResult2 = await mockActor.getUserReputation(testUser, "test-category");
        switch (reputationResult2) {
            case (#ok(reputation)) {
                Debug.print("result updateReputation: " # debug_show (reputationResult2));

                assert (reputation.userId == testUser);
                assert (reputation.categoryId == "test-category");
                assert (reputation.score == 200);
            };
            case (#err(e)) {
                Debug.print("result updateReputation: " # debug_show (e));

                assert (false); // This should not happen
            };
        };

        // Third update
        let result3 = await mockActor.updateReputation(testUser, "test-category", -300);
        Debug.print("Negative update result: " # debug_show (result3));
        assert (Result.isOk(result3));

        let reputationResult3 = await mockActor.getUserReputation(testUser, "test-category");
        switch (reputationResult3) {
            case (#ok(reputation)) {
                Debug.print("result updateReputation: " # debug_show (reputationResult3));

                assert (reputation.userId == testUser);
                assert (reputation.categoryId == "test-category");
                assert (reputation.score == -100);
            };
            case (#err(e)) {
                Debug.print("result updateReputation: " # debug_show (e));

                assert (false); // This should not happen
            };
        };
    };

    // Add other test functions here...

    // Run all tests
    public func runAllTests() : async () {
        await testCreateCategory();
        await testGetCategory();
        await testUpdateReputation();
        // Call other test functions here
        Debug.print("All tests passed successfully!");
    };
};
