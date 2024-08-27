import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ReputationActor "canister:derep"; 

actor class ReputationActorTest() {
   var reputationActor = ReputationActor;

    // Инициализация ReputationActor
    public func initialize() : async () {
        reputationActor := ReputationActor;
        Debug.print("ReputationActor initialized");
    };
    // Helper function to create a test principal
    func createTestPrincipal() : Principal {
        return Principal.fromText("aaaaa-aa");    
    };

 
    // Test functions
    public func testCreateCategory() : async () {
        Debug.print("Running testCreateCategory");
     //   let reputationActor = getReputationActor();
        let result = await reputationActor.createCategory("test-category", "Test Category", "This is a test category", null);
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
      //  let reputationActor = getReputationActor();

        let result = await reputationActor.getCategory("test-category");
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

      //  let reputationActor = getReputationActor();

        let testUser = createTestPrincipal();
        let result = await reputationActor.updateReputation(testUser, "test-category", 100);
        assert (Result.isOk(result));

        let reputationResult = await reputationActor.getUserReputation(testUser, "test-category");
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
        let result2 = await reputationActor.updateReputation(testUser, "test-category", 100);
        assert (Result.isOk(result2));

        let reputationResult2 = await reputationActor.getUserReputation(testUser, "test-category");
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
        let result3 = await reputationActor.updateReputation(testUser, "test-category", -300);
        Debug.print("Negative update result: " # debug_show (result3));
        assert (Result.isOk(result3));

        let reputationResult3 = await reputationActor.getUserReputation(testUser, "test-category");
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
       // await initialize();
        await testCreateCategory();
        await testGetCategory();
        await testUpdateReputation();
        // Call other test functions here
        Debug.print("All tests passed successfully!");
    };
};
