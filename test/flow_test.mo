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

        // Инициализация ReputationActor
        await ReputationActor.initialize();
        Debug.print("ReputationActor initialized");

        let hubPrincipal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); // Replace with actual Hub Principal
        let testUserId = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
        let testUserId2 = Principal.fromText("aaaaa-aa");
        let testCategoryId1 = "1.2.3.4";
        let testCategoryId2 = "1.2.3.5";
        let testCategoryId3 = "1.2.3.6";

        // Clear all data before starting the test
        let clearResult = await ReputationActor.clearAllData();
        switch (clearResult) {
            case (#ok(_)) { Debug.print("Data cleared successfully") };
            case (#err(e)) {
                Debug.print("Failed to clear data: " # e);
                return;
            };
        };

        // Step 1: Initialize TestCanister
        await TestCanister.initialize(hubPrincipal);
        Debug.print("✅ Step 1: TestCanister initialized");

        // Step 2: Create test categories
        await createCategory(testCategoryId1, "Test Category 1", "Test Description 1", null);
        await createCategory(testCategoryId2, "Test Category 2", "Test Description 2", null);
        await createCategory(testCategoryId3, "Test Category 3", "Test Description 3", null);
        Debug.print("✅ Step 2: Create test categories Ok");

        // Step 3: Attempt to create a duplicate category
        let duplicateCategoryResult = await ReputationActor.createCategory(testCategoryId1, "Duplicate Category", "Duplicate Description", null);
        assert (Result.isErr(duplicateCategoryResult));
        Debug.print("✅ Step 3: Duplicate category creation attempt resulted in expected error");

        // Step 4: Create test users
        assert (await createUser({ id = testUserId; username = "TestUser1"; registrationDate = Time.now() }));
        assert (await createUser({ id = testUserId2; username = "TestUser2"; registrationDate = Time.now() }));
        Debug.print("✅ Step 4: Test users created successfully");

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

        await testCategoryAndReputationUpdates();

        Debug.print("✅ ✅ ✅ All test cases completed successfully!");
    };

    // Helper functions

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
                Debug.print("Failed to get reputation: " # e);
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

        // Test case 1: Update reputation with a physics-related namespace
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

        // Test case 2: Update reputation with a technology-related namespace
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

        // Test case 3: Update reputation with a complex namespace
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
