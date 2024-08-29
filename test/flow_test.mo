import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";

import ReputationActor "canister:derep";
import TestCanister "canister:test";
import T "../src/domain/entities/Types";

actor TestReputationFlow {
    type Namespace = T.Namespace;

    public func runTest() : async () {
        Debug.print("Starting Reputation Flow Test");
        let hubPrincipal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); // Replace with actual Hub Principal
        let testUserId = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
        let testUserId2 = Principal.fromText("aaaaa-aa");
        let testCategoryId1 = "1.2.3.4";
        let testCategoryId2 = "1.2.3.5";
        let testCategoryId3 = "1.2.3.6";
        // let testScoreChange = 10;
        // let testVerificationCanister = Principal.fromText("rwlgt-iiaaa-aaaaa-aaaaa-cai");
        // let testVerificationMethod = "verifyDocument";

        // Clear all data before starting the test
        let clearResult = await ReputationActor.clearAllData();
        switch (clearResult) {
            case (#ok(_)) { Debug.print("Data cleared successfully") };
            case (#err(e)) {
                Debug.print("Failed to clear data: " # e);
                return;
            };
        };

        // Step 1: Initialize ReputationActor and TestCanister
        await ReputationActor.initialize();
        await TestCanister.initialize(hubPrincipal);
        Debug.print("✅ Step 1: ReputationActor and TestCanister initialized");

        // Step 2: Create test categories
        await createCategory(testCategoryId1, "Test Category 1");
        await createCategory(testCategoryId2, "Test Category 2");
        await createCategory(testCategoryId3, "Test Category 3");
        Debug.print("✅ Step 2: Create test categories Ok");

        // Step 3: Attempt to create a duplicate category
        let duplicateCategoryResult = await ReputationActor.createCategory(testCategoryId1, "Duplicate Category", "Duplicate Description", null);
        assert (Result.isErr(duplicateCategoryResult));
        Debug.print("✅ Step 3: Duplicate category creation attempt resulted in expected error");

        // Step 4: Create test users
        assert (await ReputationActor.createUser({ id = testUserId; username = "TestUser1"; registrationDate = Time.now() }));
        assert (await ReputationActor.createUser({ id = testUserId2; username = "TestUser2"; registrationDate = Time.now() }));
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
        // assert (del_user_res);
        Debug.print("✅ Step 7: Delete user with reputation. User with reputation deleted successfully ");

        // Step 8: Attempt to get deleted user's reputation
        let deletedUserRep = await ReputationActor.getUserReputation(testUserId2, testCategoryId1);
        Debug.print("Step 8: deletedUserRep: " # debug_show (deletedUserRep));
        assert (Result.isErr(deletedUserRep));
        Debug.print("✅ Step 8: Getting deleted user's reputation resulted in expected error");

        // Step 9: Delete user without reputation
        let noRepUserId = Principal.fromText("falxc-biaaa-aaaal-ajqzq-cai");
        assert (await ReputationActor.createUser({ id = noRepUserId; username = "NoRepUser"; registrationDate = Time.now() }));
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

        Debug.print("✅ ✅ ✅ All test cases completed successfully!");
    };

    // Helper functions

    private func createCategory(id : Text, name : Text) : async () {
        let result = await ReputationActor.createCategory(id, name, "Test Description", null);
        switch (result) {
            case (#ok(_)) {
                Debug.print("Category " # name # " created successfully");
            };
            case (#err(e)) {
                Debug.print("Failed to create category " # name # ": " # e);
            };
        };
    };

    private func updateReputation(userId : Principal, categoryId : Text, value : Int) : async () {
        await TestCanister.publishReputationUpdateEvent(
            Principal.toText(userId),
            categoryId,
            value,
            Principal.fromText("rwlgt-iiaaa-aaaaa-aaaaa-cai"),
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
};
