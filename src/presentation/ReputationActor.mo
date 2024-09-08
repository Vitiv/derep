import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";

import InitialCategories "../data/datasources/InitialCategories";
import NamespaceDictionary "../data/datasources/NamespaceDictionary";
import CategoryRepositoryImpl "../data/repositories/CategoryRepositoryImpl";
import DocumentRepositoryImpl "../data/repositories/DocumentRepositoryImpl";
import NamespaceCategoryMappingRepositoryImpl "../data/repositories/NamespaceCategoryMappingRepositoryImpl";
import NotificationRepositoryImpl "../data/repositories/NotificationRepositoryImpl";
import ReputationHistoryRepositoryImpl "../data/repositories/ReputationHistoryRepositoryImpl";
import ReputationRepositoryImpl "../data/repositories/ReputationRepositoryImpl";
import UserRepositoryImpl "../data/repositories/UserRepositoryImpl";
import Category "../domain/entities/Category";
import Document "../domain/entities/Document";
import IncomingFile "../domain/entities/IncomingFile";
import Reputation "../domain/entities/Reputation";
import ReputationHistoryTypes "../domain/entities/ReputationHistoryTypes";
import T "../domain/entities/Types";
import User "../domain/entities/User";
import DocumentClassifier "../domain/services/DocumentClassifier";
import NamespaceCategoryMapper "../domain/services/NamespaceCategoryMapper";
import UseCaseFactory "../domain/use_cases/UseCaseFactory";
import ICRC72Client "../infrastructure/ICRC72Client";
import APIHandler "./APIHandler";
import VerifierWhitelistRepositoryImpl "../data/repositories/VerifierWhitelistRepositoryImpl";

actor class ReputationActor() = Self {
    private var useCaseFactory : ?UseCaseFactory.UseCaseFactory = null;
    private var apiHandler : ?APIHandler.APIHandler = null;
    private var icrc72Client : ?ICRC72Client.ICRC72ClientImpl = null;
    private var verifierWhitelistRepo : ?VerifierWhitelistRepositoryImpl.VerifierWhitelistRepositoryImpl = null;

    private stable var stableWhitelist : [(Principal, Bool)] = [];

    public shared func initialize() : async () {
        Debug.print("Starting ReputationActor initialization...");

        // Create repositories and services
        let userRepo = UserRepositoryImpl.UserRepositoryImpl();
        let reputationRepo = ReputationRepositoryImpl.ReputationRepositoryImpl();
        let categoryRepo = CategoryRepositoryImpl.CategoryRepositoryImpl();
        let documentRepo = DocumentRepositoryImpl.DocumentRepositoryImpl();
        let notificationRepo = NotificationRepositoryImpl.NotificationRepositoryImpl();
        let reputationHistoryRepo = ReputationHistoryRepositoryImpl.ReputationHistoryRepositoryImpl();
        let namespaceMappingRepo = NamespaceCategoryMappingRepositoryImpl.NamespaceCategoryMappingRepositoryImpl();
        let documentClassifier = DocumentClassifier.DocumentClassifier();

        verifierWhitelistRepo := ?VerifierWhitelistRepositoryImpl.VerifierWhitelistRepositoryImpl();

        // Create ICRC72Client
        let broadcaster = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); // Replace with actual broadcaster Principal
        icrc72Client := ?ICRC72Client.ICRC72ClientImpl(broadcaster, Principal.fromActor(Self));

        let namespaceCategoryMapper = NamespaceCategoryMapper.NamespaceCategoryMapper(categoryRepo, namespaceMappingRepo, documentClassifier);

        // Create UseCaseFactory
        switch (icrc72Client, verifierWhitelistRepo) {
            case (?client, ?whitelistRepo) {
                useCaseFactory := ?UseCaseFactory.UseCaseFactory(
                    userRepo,
                    reputationRepo,
                    categoryRepo,
                    notificationRepo,
                    reputationHistoryRepo,
                    namespaceMappingRepo,
                    client,
                    namespaceCategoryMapper,
                    documentClassifier,
                    documentRepo,
                );

                switch (useCaseFactory) {
                    case (?factory) {
                        // Initialize VerifierWhitelist
                        whitelistRepo.whitelist := HashMap.fromIter<Principal, Bool>(stableWhitelist.vals(), 10, Principal.equal, Principal.hash);
                        stableWhitelist := [];

                        // Add the main actor's ID to the whitelist if it's not already there
                        switch (whitelistRepo.whitelist.get(Principal.fromActor(Self))) {
                            case (null) {
                                whitelistRepo.whitelist.put(Principal.fromActor(Self), true);
                                Debug.print("Added main actor to whitelist");
                            };
                            case (?_) {
                                Debug.print("Main actor already in whitelist");
                            };
                        };

                        // Add the main actor's ID to the whitelist if it's not already there
                        let checkWhitelistUseCase = factory.getCheckWhitelistUseCase();
                        let addToWhitelistUseCase = factory.getAddToWhitelistUseCase();
                        if (not (await checkWhitelistUseCase.execute(Principal.fromActor(Self)))) {
                            ignore await addToWhitelistUseCase.execute(Principal.fromActor(Self));
                            Debug.print("Added main actor to whitelist");
                        };

                        apiHandler := ?APIHandler.APIHandler(factory);

                        // Subscribe to reputation update events
                        ignore await client.subscribe(T.UPDATE_REPUTATION_NAMESPACE);
                        Debug.print("Subscribed to " # T.UPDATE_REPUTATION_NAMESPACE);

                        // Initialize categories
                        Debug.print("ReputationActor.initialize: Starting category initialization...");
                        let flatCategories = InitialCategories.flattenCategories(InitialCategories.initialCategories);
                        for (category in flatCategories.vals()) {
                            switch (await categoryRepo.getCategory(category.id)) {
                                case (null) {
                                    let result = await categoryRepo.createCategory(category);
                                    if (result) {
                                        Debug.print("Category created: " # category.id);
                                    } else {
                                        Debug.print("Failed to create category: " # category.id);
                                    };
                                };
                                case (?existingCategory) {
                                    Debug.print("Category already exists: " # existingCategory.id);
                                };
                            };
                        };
                        Debug.print("ReputationActor.initialize: Category initialization completed");

                        // Initialize predefined namespace-category mappings
                        Debug.print("ReputationActor.initialize: Starting namespace-category mapping initialization...");
                        for ((namespace, categoryId) in NamespaceDictionary.initialMappings.vals()) {
                            let result = await namespaceMappingRepo.addNamespaceCategoryMapping(namespace, categoryId);
                            if (result) {
                                Debug.print("Mapping added: " # namespace # " -> " # categoryId);
                            } else {
                                Debug.print("Failed to add mapping: " # namespace # " -> " # categoryId);
                            };
                        };
                        Debug.print("ReputationActor.initialize: Namespace-category mapping initialization completed");

                    };
                    case (null) {
                        Debug.print("Failed to create UseCaseFactory");
                    };
                };
            };
            case (_, _) Debug.print("Failed to initialize ICRC72Client");
        };

        Debug.print("ReputationActor initialization completed successfully");
    };

    public shared func updateReputation(user : Principal, category : Text, value : Int) : async Result.Result<Int, Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.updateReputation(user, category, value);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUserReputation(userId : User.UserId, categoryId : Category.CategoryId) : async Result.Result<Reputation.Reputation, Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.getUserReputation(userId, categoryId);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func createCategory(id : Text, name : Text, description : Text, parentId : ?Text) : async Result.Result<Category.Category, Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.createCategory(id, name, description, parentId);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getCategory(id : Category.CategoryId) : async Result.Result<Category.Category, Text> {
        Debug.print("ReputationActor.getCategory: Requesting category with id: " # id);
        switch (apiHandler) {
            case (?handler) {
                let result = await handler.getCategory(id);
                Debug.print("ReputationActor.getCategory: Result: " # debug_show (result));
                result;
            };
            case (null) {
                Debug.print("ReputationActor.getCategory: API Handler not initialized");
                #err("API Handler not initialized");
            };
        };
    };

    public shared func updateCategory(category : Category.Category) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.updateCategory(category) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func listCategories() : async [Category.Category] {
        switch (apiHandler) {
            case (?handler) { await handler.listCategories() };
            case (null) { [] };
        };
    };

    public shared func createUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.createUser(user) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUser(userId : User.UserId) : async Result.Result<?User.User, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getUser(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func updateUser(user : User.User) : async Result.Result<Bool, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.updateUser(user) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func deleteUser(userId : User.UserId) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.deleteUser(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func deleteCategory(categoryId : Category.CategoryId) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.deleteCategory(categoryId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func listUsers() : async Result.Result<[User.User], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.listUsers() };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getUsersByUsername(username : Text) : async Result.Result<[User.User], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getUsersByUsername(username) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getAllReputations() : async Result.Result<[Reputation.Reputation], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getAllReputations() };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getTopUsersByCategoryId(categoryId : Category.CategoryId, limit : Nat) : async Result.Result<[(User.UserId, Int)], Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.getTopUsersByCategoryId(categoryId, limit);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getTotalUserReputation(userId : User.UserId) : async Result.Result<Int, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getTotalUserReputation(userId) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func clearAllData() : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) {
                let result = await handler.clearAllData();
                switch (result) {
                    case (#ok(_)) {
                        // Reinitialize categories after clearing
                        await initialize();
                    };
                    case (#err(_)) {};
                };
                result;
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func icrc72_handle_notification(notifications : [T.EventNotification]) : async () {
        switch (apiHandler) {
            case (?handler) { await handler.handleNotification(notifications) };
            case (null) { Debug.print("API Handler not initialized") };
        };
    };

    public func getNotifications(namespace : T.Namespace) : async [T.EventNotification] {
        switch (apiHandler) {
            case (?handler) { await handler.getNotifications(namespace) };
            case (null) { [] };
        };
    };

    public func getReputationHistory(userId : Principal, categoryId : ?Text) : async Result.Result<[ReputationHistoryTypes.ReputationChange], Text> {
        switch (apiHandler) {
            case (?handler) {
                let reputationHistoryUseCase = handler.getReputationHistoryUseCase();
                try {
                    let history = await reputationHistoryUseCase.getReputationHistory(userId, categoryId);
                    #ok(history);
                } catch (error) {
                    Debug.print("Error getting reputation history: " # Error.message(error));
                    #err("Failed to get reputation history");
                };
            };
            case (null) {
                Debug.print("UseCaseFactory not initialized");
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public func determineCategories(namespace : Text, documentUrl : ?Text) : async [Category.CategoryId] {
        switch (apiHandler) {
            case (?handler) {
                let determineCategoriesUseCase = handler.getDetermineCategoriesUseCase();
                await determineCategoriesUseCase.execute(namespace, documentUrl);
            };
            case (null) { [] };
        };
    };

    public func getNamespacesForCategory(categoryId : Category.CategoryId) : async [Text] {
        switch (apiHandler) {
            case (?handler) {
                await handler.getNamespacesForCategory(categoryId);
            };
            case (null) { [] };
        };
    };

    // ----------------------------------Document Part ---------------------

    public shared (msg) func uploadDocument(file : IncomingFile.IncomingFile) : async Result.Result<Document.DocumentId, Text> {
        Debug.print("ReputationActor: Uploading document for user " # Principal.toText(msg.caller));
        switch (apiHandler) {
            case (?handler) {
                let incomingFile : IncomingFile.IncomingFile = {
                    name = file.name;
                    content = file.content;
                    contentType = file.contentType;
                    user = Principal.toText(msg.caller);
                    sourceUrl = file.sourceUrl;
                    categories = file.categories;
                };
                await handler.processIncomingFile(incomingFile, msg.caller);
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared (msg) func verifyDocumentSource(documentId : Document.DocumentId, reviewer : ?Principal) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) {
                Debug.print("ReputationActor: Verifying document source for ID: " # debug_show (documentId));
                let actualReviewer = switch (reviewer) {
                    case (?r) { r };
                    case (null) { msg.caller };
                };
                let result = await handler.verifyDocumentSource(documentId, actualReviewer);
                Debug.print("ReputationActor: Verification result: " # debug_show (result));
                result;
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared (msg) func updateDocumentCategories(documentId : Document.DocumentId, newCategories : [Text]) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) {
                Debug.print("ReputationActor: Updating document categories for ID: " # debug_show (documentId));
                let result = await handler.updateDocumentCategories(documentId, newCategories, msg.caller);
                Debug.print("ReputationActor: Update categories result: " # debug_show (result));
                result;
            };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getDocument(id : Document.DocumentId) : async Result.Result<Document.Document, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.getDocument(id) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func updateDocument(doc : Document.Document) : async Result.Result<Int, Text> {
        switch (apiHandler) {
            case (?handler) { await handler.updateDocument(doc) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func listUserDocuments(user : Principal) : async Result.Result<[Document.Document], Text> {
        switch (apiHandler) {
            case (?handler) { await handler.listUserDocuments(user) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public shared func deleteDocument(id : Document.DocumentId) : async Result.Result<(), Text> {
        switch (apiHandler) {
            case (?handler) { await handler.deleteDocument(id) };
            case (null) { #err("API Handler not initialized") };
        };
    };

    public func getDocumentVersions(id : Document.DocumentId) : async Result.Result<[Document.Document], Text> {
        switch (apiHandler) {
            case (?handler) {
                await handler.getDocumentVersions(id);
            };
            case (null) {
                #err("API Handler not initialized");
            };
        };
    };

    //--------------------------------------------- Whitelist--------------------------------------
    public shared ({ caller }) func addVerifierToWhitelist(verifier : Principal) : async Result.Result<(), Text> {
        // assert (caller == Principal.fromActor(Self) or (await isVerifierWhitelisted(caller)));
        switch (useCaseFactory) {
            case (?factory) {
                let addToWhitelistUseCase = factory.getAddToWhitelistUseCase();
                await addToWhitelistUseCase.execute(verifier);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public shared ({ caller }) func removeVerifierFromWhitelist(verifier : Principal) : async Result.Result<(), Text> {
        assert (caller == Principal.fromActor(Self));
        switch (useCaseFactory) {
            case (?factory) {
                let removeFromWhitelistUseCase = factory.getRemoveFromWhitelistUseCase();
                await removeFromWhitelistUseCase.execute(verifier);
            };
            case (null) {
                #err("UseCaseFactory not initialized");
            };
        };
    };

    public func isVerifierWhitelisted(verifier : Principal) : async Bool {
        switch (useCaseFactory) {
            case (?factory) {
                let checkWhitelistUseCase = factory.getCheckWhitelistUseCase();
                await checkWhitelistUseCase.execute(verifier);
            };
            case (null) {
                false;
            };
        };
    };

    public func getWhitelistedVerifiers() : async [Principal] {
        switch (useCaseFactory) {
            case (?factory) {
                let getWhitelistUseCase = factory.getGetWhitelistUseCase();
                await getWhitelistUseCase.execute();
            };
            case (null) { [] };
        };
    };
    //------------------------------------------- Stable part ----------------------------------------

    // System methods remain unchanged
    system func preupgrade() {
        switch (verifierWhitelistRepo) {
            case (?repo) {
                stableWhitelist := Iter.toArray(repo.whitelist.entries());
                // Debug.print("Saved whitelist state for upgrade: " # debug_show (stableWhitelist));
            };
            case (null) {
                // Debug.print("VerifierWhitelistRepository not available, cannot save whitelist state");
            };
        };
    };

    system func postupgrade() {};
};
