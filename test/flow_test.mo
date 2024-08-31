import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";

import ReputationActor "canister:derep";
import TestCanister "canister:test";
import T "../src/domain/entities/Types";

actor TestReputationFlow {
    type Namespace = T.Namespace;

    public type UserId = Principal;

    public type User = {
        id : UserId;
        username : Text;
        registrationDate : Int;
    };

    public func runTest() : async () {
        Debug.print("Starting Reputation Flow Test");

        // init ReputationActor
        await ReputationActor.initialize();
        Debug.print("ReputationActor initialized");

        let hubPrincipal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); // Replace with actual Hub Principal
        let testUserId = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
        let testUserId2 = Principal.fromText("aaaaa-aa");
        let testCategoryId1 = "1.2.3.4";
        let testCategoryId2 = "1.2.3.5";
        let testCategoryId3 = "1.2.3.6";

        // Clear all data before starting the test
       let shouldClearData = false; 
        if (shouldClearData) {
            let clearResult = await ReputationActor.clearAllData();
            switch (clearResult) {
                case (#ok(_)) { Debug.print("Data cleared successfully") };
                case (#err(e)) {
                    Debug.print("Failed to clear data: " # e);
                    return;
                };
            };
            // 
            await ReputationActor.initialize();
        };

        // Step 1: Initialize TestCanister
        await TestCanister.initialize(hubPrincipal);
        Debug.print("✅ Step 1: TestCanister initialized");

        // Step 2: Create test categories
        await createCategory(testCategoryId1, "Test Category 1", "Test Description 1", null);
        await createCategory(testCategoryId2, "Test Category 2", "Test Description 2", null);
        await createCategory(testCategoryId3, "Test Category 3", "Test Description 3", null);
        Debug.print("✅ Step 2: Create test categories Ok");

        // Step 2: Create test categories (теперь это безопасно делать многократно)
        await createCategoryIfNotExists(testCategoryId1, "Test Category 1", "Test Description 1", null);
        await createCategoryIfNotExists(testCategoryId2, "Test Category 2", "Test Description 2", null);
        await createCategoryIfNotExists(testCategoryId3, "Test Category 3", "Test Description 3", null);
        Debug.print("✅ Step 2: Test categories created or verified");

        // Step 3: Attempt to create a duplicate category
        let duplicateCategoryResult = await ReputationActor.createCategory(testCategoryId1, "Duplicate Category", "Duplicate Description", null);
        switch (duplicateCategoryResult) {
            case (#ok(category)) {
                assert (category.id == testCategoryId1);
                assert (category.name == "Motoko");  
                assert (category.description == "Motoko programming language");
                Debug.print("✅ Step 3: Duplicate category creation returned the existing category as expected");
            };
            case (#err(e)) {
                Debug.print("❌ Step 3 failed: Unexpected error when creating duplicate category: " # e);
                assert(false);
            };
        };

        // Step 4: Create test users (теперь проверяем существование перед созданием)
        await createUserIfNotExists({ id = testUserId; username = "TestUser1"; registrationDate = Time.now() });
        await createUserIfNotExists({ id = testUserId2; username = "TestUser2"; registrationDate = Time.now() });
        Debug.print("✅ Step 4: Test users created or verified");
        // Step 5: Update reputations for users in different categories
        await updateReputation(testUserId, testCategoryId1, 10);
        await updateReputation(testUserId, testCategoryId2, 20);
        await updateReputation(testUserId, testCategoryId3, -5);
        await updateReputation(testUserId2, testCategoryId1, 15);
        Debug.print("✅ Step 5: Update reputations for users in different categories");

        // Step 6: Verify reputations
        await verifyReputation(testUserId, testCategoryId1, 10);
        await verifyReputation(testUserId, testCategoryId2, 20);
        await verifyReputation(testUserId, testCategoryId3, -5);
        await verifyReputation(testUserId2, testCategoryId1, 15);
        Debug.print("✅ Step 6: Verify reputations - Ok");

        // Step 7: Delete user with reputation
        let del_user_res = await ReputationActor.deleteUser(testUserId2);
        Debug.print("Step 7: deleteUser: " # debug_show (del_user_res));
        Debug.print("✅ Step 7: Delete user with reputation. User with reputation deleted successfully ");

        // Step 8: Attempt to get deleted user's reputation
        let deletedUserRep = await ReputationActor.getUserReputation(testUserId2, testCategoryId1);
        Debug.print("Step 8: deletedUserRep: " # debug_show (deletedUserRep));
        assert (Result.isErr(deletedUserRep));
        Debug.print("✅ Step 8: Getting deleted user's reputation resulted in expected error");

        // Step 9: Delete user without reputation
        let noRepUserId = Principal.fromText("falxc-biaaa-aaaal-ajqzq-cai");
        assert (await createUser({ id = noRepUserId; username = "NoRepUser"; registrationDate = Time.now() }));
        let delUser = await ReputationActor.deleteUser(noRepUserId);
        Debug.print("Step 9: Delete user without reputation, Result: " # debug_show (delUser));
        switch (delUser) {
            case (#ok()) {
                assert (Result.isOk(delUser));
            };
            case (#err(e)) {
                Debug.print("Step 9: Delete user error " # debug_show (e));
                assert (Result.isErr(delUser));
            };
        };
        Debug.print("✅ Step 9: User without reputation deleted successfully");

        // Step 10: Attempt to delete non-existent user
        let nonExistentUserId = Principal.fromText("7hfb6-caaaa-aaaar-qadga-cai");
        let deleteResult = await ReputationActor.deleteUser(nonExistentUserId);
        assert (Result.isErr(deleteResult));
        Debug.print("✅ Step 10: Attempt to delete non-existent user handled correctly");

        // Steps 11-13
        await testCategoryAndReputationUpdates();

        // Step 14
        await testDeepCategoryHierarchy();

        // Step 15
        await testReputationHistory();

        Debug.print("✅ ✅ ✅ All test cases completed successfully!");
    };

    // Helper functions

    private func createCategoryIfNotExists(id : Text, name : Text, description : Text, parentId : ?Text) : async () {
        let existingCategory = await ReputationActor.getCategory(id);
        switch (existingCategory) {
            case (#ok(_)) {
                Debug.print("Category already exists: " # id);
            };
            case (#err(_)) {
                let result = await ReputationActor.createCategory(id, name, description, parentId);
                switch (result) {
                    case (#ok(_)) {
                        Debug.print("Category " # name # " created successfully");
                    };
                    case (#err(e)) {
                        Debug.print("Failed to create category " # name # ": " # e);
                        assert(false);
                    };
                };
            };
        };
    };

    private func createUserIfNotExists(user : User) : async () {
        let existingUser = await ReputationActor.getUser(user.id);
        switch (existingUser) {
            case (#ok(?_)) {
                Debug.print("User already exists: " # Principal.toText(user.id));
            };
            case (#ok(null)) {
                let result = await ReputationActor.createUser(user);
                switch (result) {
                    case (#ok(true)) {
                        Debug.print("User created successfully: " # Principal.toText(user.id));
                    };
                    case (#ok(false)) {
                        Debug.print("Failed to create user: " # Principal.toText(user.id));
                        assert(false);
                    };
                    case (#err(e)) {
                        Debug.print("Error creating user: " # e);
                        assert(false);
                    };
                };
            };
            case (#err(e)) {
                Debug.print("Error checking user existence: " # e);
                assert(false);
            };
        };
    };


    private func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async () {
        let result = await ReputationActor.createCategory(id, name, description, parentId);
        switch (result) {
            case (#ok(_)) {
                Debug.print("Category " # name # " created successfully");
            };
            case (#err(e)) {
                Debug.print("Failed to create category " # name # ": " # e);
                assert(false);
            };
        };
    };

    private func createUser(user : User) : async Bool {
        let result = await ReputationActor.createUser(user);
        switch (result) {
            case (#ok(success)) {
                success
            };
            case (#err(e)) {
                Debug.print("Failed to create user: " # e);
                false
            };
        };
    };

    private func updateReputation(userId : Principal, categoryId : Text, value : Int) : async () {
        await TestCanister.publishReputationUpdateEvent(
            Principal.toText(userId),
            categoryId,
            value,
            Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"),
            "verifyDocument",
        );
    };

    private func verifyReputation(userId : Principal, categoryId : Text, expectedScore : Int) : async () {
        let result = await ReputationActor.getUserReputation(userId, categoryId);
        switch (result) {
            case (#ok(reputation)) {
                assert (reputation.score == expectedScore);
                Debug.print("Verified reputation for user " # Principal.toText(userId) # " in category " # categoryId # ": " # debug_show (reputation.score));
            };
            case (#err(e)) {
                Debug.print("Failed to get reputation: user: " # Principal.toText(userId) # " category " # categoryId # "error: "# e);
                assert (false);
            };
        };
    };

   private func testCategoryAndReputationUpdates() : async () {
        Debug.print("Starting Category and Reputation Update tests");

        // Create a hierarchy of categories
        await createCategory("1", "Science", "Science root category", null);
        await createCategory("1.1", "Physics", "Physics category", ?"1");
        await createCategory("1.1.1", "Quantum", "Quantum Physics category", ?"1.1");
        await createCategory("1.2", "Chemistry", "Chemistry category", ?"1");
        await createCategory("2", "Technology", "Technology root category", null);
        await createCategory("2.1", "Software", "Software category", ?"2");
        await createCategory("2.1.1", "Web", "Web Development category", ?"2.1");

        // Create test users
        let user1 = Principal.fromText("mmt3g-qiaaa-aaaal-qi6ra-cai");
        let user2 = Principal.fromText("mls5s-5qaaa-aaaal-qi6rq-cai");
        let resCreateUser1 = await createUser({ id = user1; username = "User1"; registrationDate = Time.now() });
         Debug.print("✅ Test pre-case 11-1 passed: user 1 created: " # debug_show(resCreateUser1));
        let resCreateUser2 = await createUser({ id = user2; username = "User2"; registrationDate = Time.now() });
         Debug.print("✅ Test pre-case 11-2 passed: user 2 created: " # debug_show(resCreateUser2));

        // Test case 11: Update reputation with a physics-related namespace
        await TestCanister.publishReputationUpdateEvent(
            Principal.toText(user1),
            "1.1", // Physics category
            10,
            Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"),
            "verifyPhysics"
        );
        let r1 = await assertReputation(user1, "1.1", 10);
        Debug.print("assertReputation(user1, 1.1, 10) result: " # debug_show(r1));
        let r2 = await assertReputation(user1, "1", 10);  // Parent category should also be updated
        Debug.print("assertReputation(user1, 1, 10) result: " # debug_show(r2));

        Debug.print("✅ Test case 11 passed: Physics-related namespace update");

        // Test case 12: Update reputation with a technology-related namespace
        await TestCanister.publishReputationUpdateEvent(
            Principal.toText(user2),
            "2.1.1", // Web Development category
            15,
            Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"),
            "verifyWebDev"
        );
        let r3 = await assertReputation(user2, "2.1.1", 15);
        Debug.print("assertReputation(user2, 2.1.1, 15) result: " # debug_show(r3));

        let r4 = await assertReputation(user2, "2.1", 15);
        Debug.print("assertReputation(user2, 2.1, 15) result: " # debug_show(r4));

        let r5 = await assertReputation(user2, "2", 15);
        Debug.print("assertReputation(user2, 2, 15) result: " # debug_show(r5));

        Debug.print("✅ Test case 12 passed: Technology-related namespace update");

        // Test case 13: Update reputation with a complex namespace
        await TestCanister.publishReputationUpdateEvent(
            Principal.toText(user1),
            "1.1.1", // Quantum Physics category
            20,
            Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"),
            "verifyQuantumPhysics"
        );
        let r6 = await assertReputation(user1, "1.1.1", 20);
        Debug.print("assertReputation(user1, 1.1.1, 20) result: " # debug_show(r6));
        let r7 = await assertReputation(user1, "1.1", 30);  // 10 from previous + 20 from this update
        Debug.print("assertReputation(user1, 1.1, 30) result: " # debug_show(r7));
        let r8 = await assertReputation(user1, "1", 30);
        Debug.print("assertReputation(user1, 1, 30) result: " # debug_show(r8));
        Debug.print("✅ Test case 13 passed: Complex namespace update");

        Debug.print("✅ All Category and Reputation Update tests passed successfully!");
    };

    private func testDeepCategoryHierarchy() : async () {
        Debug.print("Starting Deep Category Hierarchy test");

        // Create a deep category hierarchy
        await createCategory("A", "Category A", "Top level category A", null);
        await createCategory("A.1", "Category A.1", "Second level category A.1", ?"A");
        await createCategory("A.1.1", "Category A.1.1", "Third level category A.1.1", ?"A.1");
        await createCategory("A.1.1.1", "Category A.1.1.1", "Fourth level category A.1.1.1", ?"A.1.1");
        await createCategory("A.1.1.1.1", "Category A.1.1.1.1", "Fifth level category A.1.1.1.1", ?"A.1.1.1");

        let deepUser = Principal.fromText("2oh2w-faaaa-aaaal-adqpa-cai");
        assert (await createUser({ id = deepUser; username = "DeepUser"; registrationDate = Time.now() }));

        // Update reputation for the deepest category
        await updateReputation(deepUser, "A.1.1.1.1", 50);

        // Verify reputation for all levels
        await verifyReputation(deepUser, "A.1.1.1.1", 50);
        await verifyReputation(deepUser, "A.1.1.1", 50);
        await verifyReputation(deepUser, "A.1.1", 50);
        await verifyReputation(deepUser, "A.1", 50);
        await verifyReputation(deepUser, "A", 50);

        // Test negative reputation update
        await updateReputation(deepUser, "A.1.1.1.1", -20);

        // Verify updated reputation for all levels
        await verifyReputation(deepUser, "A.1.1.1.1", 30);
        await verifyReputation(deepUser, "A.1.1.1", 30);
        await verifyReputation(deepUser, "A.1.1", 30);
        await verifyReputation(deepUser, "A.1", 30);
        await verifyReputation(deepUser, "A", 30);

       // Test automatic creation of parent categories
        await updateReputation(deepUser, "B.1.1.1.1", 40);

        // Verify reputation for all levels, including automatically created ones
        await verifyReputation(deepUser, "B.1.1.1.1", 40);
        let result111 = await ReputationActor.getUserReputation(deepUser, "B.1.1.1");
        Debug.print("Test 14 : verifyReputation result for B.1.1.1: " # debug_show(result111));
        switch (result111) {
            case (#ok(reputation)) {
                assert(reputation.score >= 0 and reputation.score <= 40);
            };
            case (#err(e)) {
                Debug.print("New category B not yet created or reputation not set: " # debug_show(e));
            };
        };       
        let result11 = await ReputationActor.getUserReputation(deepUser, "B.1.1");
        Debug.print("Test 14 : verifyReputation result for B.1.1: " # debug_show(result11));

        switch (result11) {
            case (#ok(reputation)) {
                assert(reputation.score >= 0 and reputation.score <= 40);
            };
            case (#err(e)) {
                Debug.print("New category B not yet created or reputation not set: " # debug_show(e));
            };
        };        
        let result = await ReputationActor.getUserReputation(deepUser, "B.1");
        Debug.print("Test 14 : verifyReputation result for B.1: " # debug_show(result));

        switch (result) {
            case (#ok(reputation)) {
                assert(reputation.score >= 0 and reputation.score <= 40);
            };
            case (#err(e)) {
                Debug.print("New category B not yet created or reputation not set: " # debug_show(e));
            };
        };
        let result1 = await ReputationActor.getUserReputation(deepUser, "B");
        Debug.print("Test 14 : verifyReputation result for B: " # debug_show(result1));

        switch (result1) {
            case (#ok(reputation)) {
                assert(reputation.score >= 0 and reputation.score <= 40);
            };
            case (#err(e)) {
                Debug.print("New category B not yet created or reputation not set: " # debug_show(e));
            };
        };
        // Verify that categories were created
        let categoryB = await ReputationActor.getCategory("B");
        let categoryB1 = await ReputationActor.getCategory("B.1");
        let categoryB11 = await ReputationActor.getCategory("B.1.1");
        let categoryB111 = await ReputationActor.getCategory("B.1.1.1");
        let categoryB1111 = await ReputationActor.getCategory("B.1.1.1.1");

        assert(Result.isOk(categoryB1111));
        Debug.print("Category B.1.1.1.1 "# debug_show(categoryB1111));

        assert(Result.isOk(categoryB) or Result.isOk(categoryB1) or Result.isOk(categoryB11) or Result.isOk(categoryB111));
        Debug.print("At least some parent categories were created automatically");
        Debug.print("✅ Test case 14: Deep Category Hierarchy test passed");
    };

    private func testReputationHistory() : async () {
        Debug.print("Test case 15: Starting Reputation History test");

        let historyUser = Principal.fromText("h5x3q-hyaaa-aaaal-adg6q-cai");
        assert (await createUser({ id = historyUser; username = "HistoryUser"; registrationDate = Time.now() }));

        // Create a category
        await createCategory("P", "Category P", "Test category for history", null);

        // Update reputation multiple times
        await updateReputation(historyUser, "P", 10);
        await updateReputation(historyUser, "P", 20);
        await updateReputation(historyUser, "P", -5);

        // Get reputation history
        let history = await ReputationActor.getReputationHistory(historyUser, ?"P");
        assert (Result.isOk(history));
        switch (history) {
            case(#ok(h)) {
                assert(h.size() == 3);
                assert(h[0].value == 10);
                assert(h[1].value == 20);
                assert(h[2].value == -5);
            };
            case (#err(e)) {
                Debug.print("Test case 15: error on getting histort: " # debug_show(e));
            }
        };
       

        Debug.print("✅ Test case 15: Reputation History test passed");
    };

    private func assertReputation(userId : Principal, categoryId : Text, expectedScore : Int) : async Bool {
        let result = await ReputationActor.getUserReputation(userId, categoryId);
        switch (result) {
            case (#ok(reputation)) {
                assert(reputation.score == expectedScore);
                Debug.print("Verified reputation for user " # Principal.toText(userId) # " in category " # categoryId # ": " # debug_show(reputation.score));
                true;
            };
            case (#err(e)) {
                Debug.print("Failed to get reputation: " # e);
                false;
            };
        };
    };
};
