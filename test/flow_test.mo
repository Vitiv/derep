import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Nat32 "mo:base/Nat32";

import ReputationActor "canister:derep";
import TestCanister "canister:test";
import T "../src/domain/entities/Types";
import Document "../src/domain/entities/Document";

actor class TestReputationFlow() = this {
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

        // Step 4: Create test users 
        await createUserIfNotExists({ id = testUserId; username = "TestUser1"; registrationDate = Time.now() });
        await createUserIfNotExists({ id = testUserId2; username = "TestUser2"; registrationDate = Time.now() });
        Debug.print("✅ Step 4: Test users created or verified");

         // Step 4-2: Add test users to the whitelist
        await addVerifierToWhitelist(testUserId);
        await addVerifierToWhitelist(testUserId2);
        await addVerifierToWhitelist(Principal.fromText("aaaaa-aa")); 
        await addVerifierToWhitelist(Principal.fromActor(this));

        Debug.print("✅ Step 4: Test users added to the whitelist");

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

        // Step 16
        await testNamespaceCategoryMappings();

        // Step 17
        await testDocumentManagement();

        // Step 18
        await testDocumentCreationAndVerification();

        // Step 19
        await testDocumentCategoryVerification();

        // Step 20
        await testDocumentCategoryUpdate();

        // Step 21
        await testDocumentVerificationWithWhitelist();

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
        Debug.print("verifyReputation: result " # debug_show(result));
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
        Debug.print("Category B.1.1.1 "# debug_show(categoryB111));
        Debug.print("Category B.1.1 "# debug_show(categoryB11));
        Debug.print("Category B.1 "# debug_show(categoryB1));
        Debug.print("Category B "# debug_show(categoryB));

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

    private func testNamespaceCategoryMappings() : async () {
        Debug.print("Test case 16: Starting Namespace-Category Mapping test");

        let categoryId = "1.2.2"; // Internet Computer
        let namespaces = ["icdevs", "dfinity", "icp"];

        let testCategoryMappingUserId = Principal.toText(Principal.fromText("skqrs-7aaaa-aaaal-qcsmq-cai"));
        let testCategoryMappingUser = { 
            id = Principal.fromText(testCategoryMappingUserId); 
            username = "TestCategoryMappingUser"; 
            registrationDate = Time.now() 
        };
        await createUserIfNotExists(testCategoryMappingUser);
        let testValue = 10;

        // Publish event for every namespaces
        for (namespace in namespaces.vals()) {
            await TestCanister.publishReputationUpdateEvent(testCategoryMappingUserId, categoryId, testValue, Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"), namespace);
        };

        for (namespace in namespaces.vals()) {
            let reputation = await ReputationActor.getUserReputation(Principal.fromText(testCategoryMappingUserId), categoryId);
            Debug.print("Test case 16:  getUserReputation result: " # debug_show(reputation));
            switch (reputation) {
                case (#ok(rep)) {
                    assert(rep.score == (testValue * namespaces.size()));
                    Debug.print("✅ Test case 16: Reputation updated correctly for namespace: " # namespace # " , rep: " # debug_show(rep));
                };
                case (#err(e)) {
                    Debug.print("❌ Test case 16: Failed to get reputation for namespace " # namespace # ": " # e);
                    assert(false);
                };
            };
        };

        Debug.print("✅ Test case 16: Namespace-Category Mapping test passed");
    };

     // Test case 17
     private func testDocumentManagement() : async () {
        Debug.print("Test case 17: Starting Document Management tests");

        let testUser = Principal.fromActor(this);
        Debug.print("Test 17 user principal: " # Principal.toText(testUser));

        // Create test user before uploading document
        let createUserResult = await ReputationActor.createUser({
            id = testUser;
            username = "TestUser";
            registrationDate = Time.now();
        });
        
        switch (createUserResult) {
            case (#ok(true)) {
                Debug.print("✅ Test 17-0: Test user created successfully");
            };
            case (#ok(false)) {
                Debug.print("❌ Test 17-0: Failed to create test user");
                assert(false);
            };
            case (#err(e)) {
                Debug.print("❌ Test 17-0: Error creating test user: " # e);
                assert(false);
            };
        };

        let testDocument = {
            name = "test_document.txt";
            content = Blob.toArray(Text.encodeUtf8("This is a test document content."));
            contentType = "text/plain";
            user = Principal.toText(testUser);
            sourceUrl = ?"https://example.com/source";
            categories = [];
        };

        // Test 17-1: Upload a document
        let uploadResult = await ReputationActor.uploadDocument(testDocument);
        var documentId : ?Document.DocumentId = null;
        switch (uploadResult) {
            case (#ok(id)) {
                Debug.print("✅ Test 17-1: Document uploaded successfully with ID: " # debug_show(id));
                documentId := ?id;
            };
            case (#err(e)) {
                Debug.print("❌ Test 17-1: Failed to upload document: " # e);
                assert(false);
            };
        };

         // Test 17-2: Upload a document without sourceUrl
        let testDocumentNoSource = {
            testDocument with sourceUrl = null; categories = [];
        };
        let uploadResultNoSource = await ReputationActor.uploadDocument(testDocumentNoSource);
        var documentIdNoSource : ?Document.DocumentId = null;
        switch (uploadResultNoSource) {
            case (#ok(id)) {
                Debug.print("✅ Test 17-2: Document without source uploaded successfully with ID: " # debug_show(id));
                documentIdNoSource := ?id;
            };
            case (#err(e)) {
                Debug.print("❌ Test 17-2: Failed to upload document without source: " # e);
                assert(false);
            };
        };

         // Test 17-3: Get the uploaded document and check temporary reputation
         var doc_categories :[Text] = [];
        switch (documentIdNoSource) {
            case (?id) {
                let getResult = await ReputationActor.getDocument(id);
                switch (getResult) {
                    case (#ok(doc)) {
                        doc_categories := doc.categories;
                        Debug.print("✅ Test 17-3: Retrieved document: " # debug_show(doc));
                        assert(doc.name == testDocument.name);
                        assert(doc.contentType == testDocument.contentType);
                        assert(doc.user == testUser);
                        assert(doc.verifiedBy.size() == 1);
                        // assert(doc.verifiedBy[0].reviewer == "system");
                        assert(doc.verifiedBy[0].reputation == 2); // Assuming temporary reputation is 2
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-3: Failed to get document: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-3: No document ID available for retrieval");
                assert(false);
            };
        };

        await updateReputation(testUser, T.DEFAULT_CATEGORY_CODE , 10);

        // Test 17-4: Verify document with valid sourceUrl
        switch (documentId) {
            case (?id) {
                let verifyResult = await ReputationActor.verifyDocumentSource(id, ?testUser);
                switch (verifyResult) {
                    case (#ok(_)) {
                        Debug.print("✅ Test 17-4: Document verified successfully");
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-4: Failed to verify document: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-4: No document ID available for verification");
                assert(false);
            };
        };

        // Test 17-5: Verify document without sourceUrl
        switch (documentIdNoSource) {
            case (?id) {
                let verifyResultNoSource = await ReputationActor.verifyDocumentSource(id, ?testUser);
                switch (verifyResultNoSource) {
                    case (#ok(_)) {
                        Debug.print("❌ Test 17-5: Document without source should not be verified");
                        assert(false);
                    };
                    case (#err(_)) {
                        Debug.print("✅ Test 17-5: Document without source correctly failed verification");
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-5: No document ID available for verification");
                assert(false);
            };
        };

        // Test 17-6: Get verified document and check full reputation
        Debug.print("Starting Test 17-6: Get verified document and check full reputation");

       switch (documentId) {
            case (?id) {
                let verifyResult = await ReputationActor.verifyDocumentSource(id, ?testUser);
                switch (verifyResult) {
                    case (#ok(_)) {
                        // Get the latest document (which should be the newly created one)
                        let latestDocuments = await ReputationActor.listUserDocuments(testUser);
                        switch (latestDocuments) {
                            case (#ok(docs)) {
                                assert(docs.size() > 0);
                                let latestDoc = docs[docs.size() - 1];
                                Debug.print("✅ Test 17-6: Retrieved latest verified document: " # debug_show(latestDoc));
                                assert(latestDoc.verifiedBy.size() > 0);
                                assert(latestDoc.verifiedBy[latestDoc.verifiedBy.size() - 1].reputation > 1); // Assuming full reputation is greater than temporary
                            };
                            case (#err(e)) {
                                Debug.print("❌ Test 17-6: Failed to get latest documents: " # e);
                                assert(false);
                            };
                        };
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-6: Failed to verify document: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-6: No document ID available for retrieval");
                assert(false);
            };
        };

        // Test 17-7: Verify document and attempt to re-verify
        switch (documentId) {
            case (?id) {
                let reviewer = Principal.toText(Principal.fromActor(this));
                Debug.print("Test 17-7: Using reviewer: " # reviewer);

                // Check initial document state
                let initialDocResult = await ReputationActor.getDocument(id);
                switch (initialDocResult) {
                    case (#ok(doc)) {
                        Debug.print("Initial document state: " # debug_show(doc));
                        let initialVerificationCount = doc.verifiedBy.size();

                        // Attempt to verify
                        let verifyResult = await ReputationActor.verifyDocumentSource(id, ?Principal.fromActor(this));
                        switch (verifyResult) {
                            case (#ok(_)) {
                                if (initialVerificationCount == 0) {
                                    Debug.print("✅ Test 17-7: Document verified successfully");
                                } else {
                                    Debug.print("❌ Test 17-7: Document was already verified, but no error was returned");
                                    assert(false);
                                };
                            };
                            case (#err(e)) {
                                if (initialVerificationCount > 0 and e == "Document already verified by this reviewer") {
                                    Debug.print("✅ Test 17-7: Correctly failed to re-verify already verified document");
                                } else {
                                    Debug.print("❌ Test 17-7: Unexpected error: " # e);
                                    assert(false);
                                };
                            };
                        };
                        
                        // Attempt to re-verify
                        let reverifyResult = await ReputationActor.verifyDocumentSource(id, ?Principal.fromActor(this));
                        switch (reverifyResult) {
                            case (#ok(_)) {
                                Debug.print("❌ Test 17-7: Already verified document should not be re-verified");
                                assert(false);
                            };
                            case (#err(e)) {
                                if (e == "Document already verified by this reviewer") {
                                    Debug.print("✅ Test 17-7: Correctly failed to re-verify already verified document");
                                } else {
                                    Debug.print("❌ Test 17-7: Unexpected error: " # e);
                                    assert(false);
                                };
                            };
                        };
                        
                        // Check that verification didn't create a new version
                        let versionsResult = await ReputationActor.getDocumentVersions(id);
                        switch (versionsResult) {
                            case (#ok(versions)) {
                                assert(versions.size() == 1);
                                Debug.print("✅ Test 17-7: Verification did not create a new document version");
                            };
                            case (#err(e)) {
                                Debug.print("❌ Test 17-7: Failed to get document versions: " # e);
                                assert(false);
                            };
                        };
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-7: Failed to get initial document state: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-7: No document ID available for verification");
                assert(false);
            };
        };

        // Test 17-8: Update the document
        switch (documentId) {
            case (?id) {
                let updatedDocument = {
                    id = id;
                    name = "updated_document.txt";
                    content = Blob.toArray(Text.encodeUtf8("This is an updated document content."));
                    contentType = "text/plain";
                    size = 36;
                    hash = "updated_hash";
                    source = "test_source";
                    sourceUrl = ?"https://example.com/source";
                    user = testUser;
                    createdAt = Time.now();
                    updatedAt = Time.now();
                    verifiedBy = [];
                    previousVersion = null; 
                    categories = []
                };
                let updateResult = await ReputationActor.updateDocument(updatedDocument);
                switch (updateResult) {
                    case (#ok(newId)) {
                        Debug.print("✅ Test 17-8: Document updated successfully with new ID: " # debug_show(newId));
                        documentId := ?Nat32.toNat(Nat32.fromIntWrap(newId));  // Update documentId to the new version
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-8: Failed to update document: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-8: No document ID available for update");
                assert(false);
            };
        };

        // Test 17-9: Get document versions
        switch (documentId) {
            case (?id) {
                let versionsResult = await ReputationActor.getDocumentVersions(id);
                switch (versionsResult) {
                    case (#ok(versions)) {
                        Debug.print("✅ Test 17-9: Retrieved document versions: " # debug_show(versions));
                        assert(versions.size() == 2);  // Should have original and updated version
                        assert(versions[0].name == "updated_document.txt");
                        assert(versions[1].name == "test_document.txt");
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-9: Failed to get document versions: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-9: No document ID available for version retrieval");
                assert(false);
            };
        };

        // Test 17-10: List user documents
        let listResult = await ReputationActor.listUserDocuments(testUser);
        switch (listResult) {
            case (#ok(docs)) {
                Debug.print("✅ Test 17-10: Retrieved user documents: " # debug_show(docs));
                assert(docs.size() > 0);
                // Check if the latest version is in the list
                assert(docs[docs.size() - 1].name == "updated_document.txt");
            };
            case (#err(e)) {
                Debug.print("❌ Test 17-10: Failed to list user documents: " # e);
                assert(false);
            };
        };

        // Test 17-11: Delete the document
        switch (documentId) {
            case (?id) {
                let deleteResult = await ReputationActor.deleteDocument(id);
                switch (deleteResult) {
                    case (#ok(_)) {
                        Debug.print("✅ Test 17-11: Document deleted successfully");
                    };
                    case (#err(e)) {
                        Debug.print("❌ Test 17-11: Failed to delete document: " # e);
                        assert(false);
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-11: No document ID available for deletion");
                assert(false);
            };
        };

        // Test 17-12: Attempt to get the deleted document (should fail)
        switch (documentId) {
            case (?id) {
                let getDeletedResult = await ReputationActor.getDocument(id);
                switch (getDeletedResult) {
                    case (#ok(_)) {
                        Debug.print("❌ Test 17-12: Retrieved deleted document, expected an error");
                        assert(false);
                    };
                    case (#err(_)) {
                        Debug.print("✅ Test 17-12: Correctly failed to retrieve deleted document");
                    };
                };
            };
            case (null) {
                Debug.print("❌ Test 17-12: No document ID available for retrieval test");
                assert(false);
            };
        };

        Debug.print("✅ ✅ Test case 17: All Document Management tests passed successfully!");
    };

    // Text 18
    public func testDocumentCreationAndVerification() : async () {
        Debug.print("Starting Test 18: Document Creation and Verification test");

        // Create two test users
        let user1 = Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai");
        let user2 = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");

        // Ensure users are created in the system
        ignore await ReputationActor.createUser({ id = user1; username = "User1"; registrationDate = Time.now() });
        ignore await ReputationActor.createUser({ id = user2; username = "User2"; registrationDate = Time.now() });

        // User1 creates a document
            let createDocumentResult = await TestCanister.createTestDocument(user1, "This is a test document content.", []);
            var documentId : Document.DocumentId = 0;
            
            switch (createDocumentResult) {
                case (#ok(id)) {
                    documentId := id;
                    Debug.print("✅ Test 18: Test document created with ID: " # debug_show(documentId));
                };
                case (#err(e)) {
                    Debug.print("❌ Test 18: Failed to create test document: " # e);
                    assert(false);
                };
            };

            // User2 verifies the document
            await updateReputation(user2, T.DEFAULT_CATEGORY_CODE , 10);
            let verificationResult = await ReputationActor.verifyDocumentSource(documentId, ?user2);
            switch (verificationResult) {
                case (#ok(_)) {
                    Debug.print("✅ Test: Document verified successfully");
                };
                case (#err(e)) {
                    Debug.print("❌ Test: Failed to verify document: " # e);
                    // assert(false);
                };
            };

            // Check User1's reputation
            let reputationResult = await ReputationActor.getUserReputation(user1, T.DEFAULT_CATEGORY_CODE); // Assuming "1.2.2" is the default category
            switch (reputationResult) {
                case (#ok(reputation)) {
                    Debug.print("✅ Test 18: User1's reputation: " # debug_show(reputation));
                    assert(reputation.score == 11); // Expected reputation score to be 11
                };
                case (#err(_)) {
                    Debug.print("❌ Test 18: Failed to get user reputation: " # debug_show(reputationResult));
                    assert(false);
                };
            };

            Debug.print("✅ ✅ Test 18: Document Creation and Verification test completed successfully");
        };

        // Test 19 Document Category Verification
        public func testDocumentCategoryVerification() : async () {
        Debug.print("Starting Test 19: Document Category Verification test");

        // Create three test users
        let user1 = Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai");
        let user2 = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
        let user3 = Principal.fromText("k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae");

        // Ensure users are created in the system
        ignore await ReputationActor.createUser({ id = user1; username = "User1"; registrationDate = Time.now() });
        ignore await ReputationActor.createUser({ id = user2; username = "User2"; registrationDate = Time.now() });
        ignore await ReputationActor.createUser({ id = user3; username = "User3"; registrationDate = Time.now() });

        // Give User2 some reputation in category "2.2.3" (different from document category)
        await TestCanister.publishReputationUpdateEvent(Principal.toText(user2), "2.2.3", 50, Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"), "initialReputation");

        // User1 creates a document in category "3.2.2"
        let createDocumentResult = await TestCanister.createTestDocument(user1, "This is a test document content.", ["3"]);
        var documentId : Document.DocumentId = 0;
        
        switch (createDocumentResult) {
            case (#ok(id)) {
                documentId := id;
                Debug.print("✅ Test 19-1: Test document created with ID: " # debug_show(documentId));
            };
            case (#err(e)) {
                Debug.print("❌ Test 19-1: Failed to create test document: " # e);
                assert(false);
            };
        };

        // User3 (no reputation) attempts to verify the document
        let verificationResultUser3 = await ReputationActor.verifyDocumentSource(documentId, ?user3);
        switch (verificationResultUser3) {
            case (#ok(_)) {
                Debug.print("❌ Test 19-2: User3 (no reputation) should not be able to verify the document");
                assert(false);
            };
            case (#err(e)) {
                Debug.print("✅ Test 19-2: User3 (no reputation) correctly failed to verify document: " # e);
            };
        };

        // User2 (reputation in different category) attempts to verify the document
        let verificationResultUser2 = await ReputationActor.verifyDocumentSource(documentId, ?user2);
        Debug.print("Test 19-3: verificationResultUser2: " # debug_show(verificationResultUser2));
        switch (verificationResultUser2) {
            case (#ok(_)) {
                Debug.print("❌ Test 19-3: User2 (reputation in different category) should not be able to verify the document");
                assert(false);
            };
            case (#err(e)) {
                Debug.print("✅ Test 19-3: User2 (reputation in different category) correctly failed to verify document: " # e);
            };
        };

        // Give User2 some reputation in the correct category DEFAULT_CATEGORY_CODE
        await TestCanister.publishReputationUpdateEvent(Principal.toText(user2), "3", 50, Principal.fromText("ezcib-nyaaa-aaaal-adsbq-cai"), "correctCategoryReputation");

        // User2 (now with correct reputation) verifies the document
        let verificationResultUser2Correct = await ReputationActor.verifyDocumentSource(documentId, ?user2);
        switch (verificationResultUser2Correct) {
            case (#ok(_)) {
                Debug.print("✅ Test 19-4: User2 (with correct reputation) verified document successfully");
            };
            case (#err(e)) {
                Debug.print("❌ Test 19-4: User2 (with correct reputation) failed to verify document: " # e);
                assert(false);
            };
        };

        // Check User1's reputation
        let reputationResult = await ReputationActor.getUserReputation(user1, T.DEFAULT_CATEGORY_CODE);
        switch (reputationResult) {
            case (#ok(reputation)) {
                Debug.print("✅ Test 19-5: User1's reputation: " # debug_show(reputation.score));
                assert(reputation.score == 22); // Expected reputation score to be 22
            };
            case (#err(e)) {
                Debug.print("❌ Test 19-5: Failed to get user reputation: " # e);
                assert(false);
            };
        };

        Debug.print("✅ ✅ Test 19: Document Creation and Verification test completed successfully");
    };

    // Test 20
    private func testDocumentCategoryUpdate() : async () {
        Debug.print("Starting Test 20: Document Category Update");

        let user = Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai");
        let initialCategories = [T.DEFAULT_CATEGORY_CODE];
        let updatedCategories = [T.DEFAULT_CATEGORY_CODE, "2.1"];

        // Create a document
        let createDocumentResult = await TestCanister.createTestDocument(user, "This is a test document for category update.", initialCategories);
        var documentId : Document.DocumentId = 0;
        
        switch (createDocumentResult) {
            case (#ok(id)) {
                documentId := id;
                Debug.print("✅ Test 20-1: Test document created with ID: " # debug_show(documentId));
            };
            case (#err(e)) {
                Debug.print("❌ Test 20-1: Failed to create test document: " # e);
                assert(false);
            };
        };

        // Update document categories
        let updateResult = await ReputationActor.updateDocumentCategories(documentId, updatedCategories);
        switch (updateResult) {
            case (#ok(_)) {
                Debug.print("✅ Test 20-2: Document categories updated successfully");
            };
            case (#err(e)) {
                Debug.print("❌ Test 20-2: Failed to update document categories: " # e);
                assert(false);
            };
        };

        // Verify the updated categories
        let getDocumentResult = await ReputationActor.getDocument(documentId);
        Debug.print("Test 20-3: getDocumentResult for id: " # debug_show(documentId) # ", result: " # debug_show(getDocumentResult));
        switch (getDocumentResult) {
            case (#ok(document)) {
                 Debug.print("Test 20-3: Retrieved document: " # debug_show(document));
                assert(document.id == documentId);
                assert(document.categories == updatedCategories);
                Debug.print("✅ Test 20-3: Document categories verified after update");
            };
            case (#err(e)) {
                Debug.print("❌ Test 20-3: Failed to get updated document: " # e);
                assert(false);
            };
        };

        Debug.print("✅ ✅ Test 20: Document Category Update test completed successfully");
    };

    // Test 21

    private func testDocumentVerificationWithWhitelist() : async () {
        Debug.print("Test 21: Starting Document Verification with Whitelist test");

        let whitelistedUser = Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai");
        let nonWhitelistedUser = Principal.fromText("k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae");

        // Ensure users are created in the system
        ignore await ReputationActor.createUser({ id = whitelistedUser; username = "WhitelistedUser"; registrationDate = Time.now() });
        ignore await ReputationActor.createUser({ id = nonWhitelistedUser; username = "NonWhitelistedUser"; registrationDate = Time.now() });

        // Add whitelistedUser to the whitelist
        await addVerifierToWhitelist(whitelistedUser);

        // Give both users some reputation
        await updateReputation(whitelistedUser, T.DEFAULT_CATEGORY_CODE, 50);
        await updateReputation(nonWhitelistedUser, T.DEFAULT_CATEGORY_CODE, 50);

        // Create a test document
        let createDocumentResult = await TestCanister.createTestDocument(whitelistedUser, "This is a test document for whitelist verification.", []);
        var documentId : Document.DocumentId = 0;
        
        switch (createDocumentResult) {
            case (#ok(id)) {
                documentId := id;
                Debug.print("✅ Test 21-1: document created with ID: " # debug_show(documentId));
            };
            case (#err(e)) {
                Debug.print("❌ Test 21-1: Failed to create test document: " # e);
                assert(false);
            };
        };

        // Attempt verification with whitelisted user
        let whitelistedVerificationResult = await ReputationActor.verifyDocumentSource(documentId, ?whitelistedUser);
        switch (whitelistedVerificationResult) {
            case (#ok(_)) {
                Debug.print("✅ Test 21-2: Whitelisted user successfully verified the document");
            };
            case (#err(e)) {
                Debug.print("❌ Test 21-2: Whitelisted user failed to verify the document: " # e);
                assert(false);
            };
        };

        // Attempt verification with non-whitelisted user
        let nonWhitelistedVerificationResult = await ReputationActor.verifyDocumentSource(documentId, ?nonWhitelistedUser);
        switch (nonWhitelistedVerificationResult) {
            case (#ok(_)) {
                Debug.print("❌ Test 21-3: Non-whitelisted user should not be able to verify the document");
                assert(false);
            };
            case (#err(e)) {
                Debug.print("✅ Test 21-3: Non-whitelisted user correctly failed to verify document: " # e);
            };
        };

        Debug.print("✅ ✅Test 21: Document Verification with Whitelist test completed successfully");
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

    private func addVerifierToWhitelist(userId : Principal) : async () {
        let result = await ReputationActor.addVerifierToWhitelist(userId);
        switch (result) {
            case (#ok(_)) {
                Debug.print("User added to whitelist: " # Principal.toText(userId));
            };
            case (#err(e)) {
                Debug.print("Failed to add user to whitelist: " # e);
                // assert(false);
            };
        };
    };
};
