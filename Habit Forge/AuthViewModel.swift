import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    // MARK: - Published properties to update UI
    @Published var userSession: FirebaseAuth.User?
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var flavorText: String?
    @Published var characterClass: String?
    @Published var username: String?
    @Published var isProfileLoading = false
    @Published var quests: [Quest] = []
    @Published var completedQuests: [Quest] = []
    @Published var dailyQuest: Quest? = nil
    @Published var userXP: Int = 0
    @Published var userLevel: Int = 1
    @Published var didLevelUp: Bool = false
    @Published var needsOnboarding: Bool = false
    @Published var finishedLoadingProfile: Bool = false
    
    // MARK: - Firestore database reference
    private var db = Firestore.firestore()
    
    // MARK: - Daily Quest UserDefaults Keys
    private func todayString() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: today)
    }
    func todayStatusKey() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let uid = userSession?.uid else { return "dailyQuestStatus-\(formatter.string(from: today))" }
        return "dailyQuestStatus-\(uid)-\(formatter.string(from: today))"
    }
    func currentDailyQuestKey() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let uid = userSession?.uid else { return "dailyQuest-\(formatter.string(from: today))" }
        return "dailyQuest-\(uid)-\(formatter.string(from: today))"
    }
    
    // MARK: - Initialize session
    init() {
        self.userSession = Auth.auth().currentUser
        self.isLoggedIn = false
        self.userSession = nil
        if self.userSession != nil {
            self.checkOrGenerateDailyQuest()
        }
    }
    
    // MARK: - Sign Up with username, email, password
    func signUp(username: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error checking username: \(error.localizedDescription)"
                    completion(.failure(error))
                }
                return
            }
            if let snapshot = snapshot, !snapshot.isEmpty {
                let usernameTakenError = NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username already taken."])
                DispatchQueue.main.async {
                    self.errorMessage = "Username already taken."
                    completion(.failure(usernameTakenError))
                }
                return
            }
            // Username is unique, create Firebase Authentication user
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async { self.isLoading = false }
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Sign-up failed: \(error.localizedDescription)"
                        completion(.failure(error))
                    }
                    return
                }
                guard let user = result?.user else {
                    let unknownError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error during user creation."])
                    DispatchQueue.main.async { completion(.failure(unknownError)) }
                    return
                }
                // Save user profile data to Firestore (initialize xp & level!)
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": email,
                    "username": username,
                    "xp": 0,
                    "level": 1
                ]
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                            completion(.failure(error))
                        } else {
                            self.errorMessage = nil
                            self.userSession = user
                            self.isLoggedIn = true
                            self.fetchUserProfile()
                            self.fetchQuests()
                            self.checkOrGenerateDailyQuest()
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    func updateUserProfile(field: String, value: String, completion: (() -> Void)? = nil) {
        guard let uid = userSession?.uid, isLoggedIn else { completion?(); return }
        DispatchQueue.main.async {
            if field == "flavorText" {
                self.flavorText = value
            } else if field == "npcClass" {
                self.characterClass = value
            }
        }
        db.collection("users").document(uid).updateData([
            field: value
        ]) { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("\(field) updated to \(value)")
                // Trigger daily quest generation now that flavor/class updated
                if field == "flavorText" || field == "npcClass" {
                    self.checkOrGenerateDailyQuest()
                }
            }
            completion?()
        }
    }
    
    
    // MARK: - Save a quest to Firestore
    func saveQuest(_ quest: Quest, completion: @escaping (Result<Void, Error>) -> Void) {
        print("SAVEQUEST CALLED! Title: \(quest.title)")
        guard let uid = userSession?.uid, isLoggedIn else {
            print("No UID or not logged in!")
            return
        }
        let questData: [String: Any] = [
            "title": quest.title,
            "flavored": quest.flavored,
            "xp": quest.xp,
            "recommendedClass": quest.recommendedClass as Any,
            "completed": quest.completed,
            "subtasks": quest.subtasks as Any,
            "timestamp": quest.timestamp,
            "isDaily": quest.isDaily
        ]
        db.collection("users")
            .document(uid)
            .collection("quests")
            .addDocument(data: questData) { error in
                if let error = error {
                    print("Error saving quest: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Quest saved successfully!")
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Fetch all quests for the user from Firestore
    func fetchQuests() {
        guard let uid = userSession?.uid, isLoggedIn else { return }
        db.collection("users").document(uid).collection("quests")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Failed to fetch quests: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.quests = documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let title = data["title"] as? String,
                          let flavored = data["flavored"] as? String,
                          let xp = data["xp"] as? Int,
                          let completed = data["completed"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    let recommendedClass = data["recommendedClass"] as? String
                    let subtasks = data["subtasks"] as? [String]
                    return Quest(
                        id: id,
                        title: title,
                        flavored: flavored,
                        xp: xp,
                        recommendedClass: recommendedClass,
                        completed: completed,
                        subtasks: subtasks,
                        timestamp: timestamp.dateValue()
                    )
                }
            }
    }
    func signInAnonymously() {
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Unknown error"
                }
                return
            }

            let userDocRef = self.db.collection("users").document(user.uid)

            userDocRef.getDocument { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                }

                if let error = error {
                    print("Error fetching user doc: \(error.localizedDescription)")
                    self.errorMessage = "Error fetching user profile"
                    return
                }

                if let snapshot = snapshot, snapshot.exists {
                    // Returning anonymous user — load profile
                    DispatchQueue.main.async {
                        self.userSession = user
                        self.isLoggedIn = true
                        self.fetchUserProfile()
                        self.fetchQuests()
                        self.checkOrGenerateDailyQuest()
                    }
                } else {
                    // First time anonymous user — create profile
                    userDocRef.setData([
                        "uid": user.uid,
                        "username": "Guest",
                        "flavorText": NSNull(),
                        "npcClass": NSNull(),
                        "xp": 0,
                        "level": 1,
                        "needsOnboarding": true // ✅ Ensures onboarding UI triggers
                    ]) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Failed to create anonymous user doc: \(error.localizedDescription)")
                                self.errorMessage = "Failed to initialize user profile"
                            }

                            self.userSession = user
                            self.isLoggedIn = true
                            self.fetchUserProfile()
                            self.fetchQuests()
                            self.checkOrGenerateDailyQuest()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mark quest as complete
    func completeQuest(questID: String) {
        guard let uid = userSession?.uid else { return }
        let questRef = db.collection("users").document(uid).collection("quests").document(questID)
        questRef.getDocument { doc, error in
            if let error = error {
                print("Error getting quest for completion: \(error.localizedDescription)")
                return
            }
            guard let data = doc?.data() else { return }
            var completedQuestData = data
            completedQuestData["completed"] = true
            if let xp = data["xp"] as? Int {
                DispatchQueue.main.async { self.addXP(xp) }
            }
            // Add to completedQuests
            self.db.collection("users").document(uid).collection("completedQuests").addDocument(data: completedQuestData) { err in
                if let err = err {
                    print("Error adding to completedQuests: \(err.localizedDescription)")
                } else {
                    // Delete from active quests
                    questRef.delete { delErr in
                        if let delErr = delErr {
                            print("Error deleting completed quest: \(delErr.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
                                self.quests.removeAll { $0.id == questID }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - fetch completed quests
    func fetchCompletedQuests() {
        guard let uid = userSession?.uid else { return }
        db.collection("users").document(uid).collection("completedQuests")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("Failed to fetch completed quests: \(error.localizedDescription)"); return }
                guard let documents = snapshot?.documents else { return }
                self.completedQuests = documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let title = data["title"] as? String,
                          let flavored = data["flavored"] as? String,
                          let xp = data["xp"] as? Int,
                          let completed = data["completed"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    let recommendedClass = data["recommendedClass"] as? String
                    let subtasks = data["subtasks"] as? [String]
                    return Quest(
                        id: id,
                        title: title,
                        flavored: flavored,
                        xp: xp,
                        recommendedClass: recommendedClass,
                        completed: completed,
                        subtasks: subtasks,
                        timestamp: timestamp.dateValue()
                    )
                }
            }
    }
    
    // MARK: - Delete a quest
    func deleteQuest(questID: String) {
        guard let uid = userSession?.uid, isLoggedIn else { return }
        db.collection("users").document(uid).collection("quests").document(questID).delete { error in
            if let error = error {
                print("Error deleting quest: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Log in (by email or username)
    func login(identifier: String, password: String, completion: @escaping(Result<Void,Error>) -> Void) {
        isLoading = true
        func signIn(with email: String) {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async { self.isLoading = false }
                if let error = error {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    let unknownError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error during login"])
                    self.errorMessage = "Unknown error during login."
                    completion(.failure(unknownError))
                    return
                }
                self.userSession = user
                self.isLoggedIn = true
                self.errorMessage = nil
                self.fetchUserProfile()
                self.fetchQuests()
                self.checkOrGenerateDailyQuest()
                completion(.success(()))
            }
        }
        if identifier.contains("@") {
            signIn(with: identifier)
        } else {
            db.collection("users").whereField("username", isEqualTo: identifier).getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to find username: \(error.localizedDescription)"
                        completion(.failure(error))
                    }
                    return
                }
                guard let document = snapshot?.documents.first,
                      let email = document.data()["email"] as? String else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Username not found."
                        completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Username not found."])))
                    }
                    return
                }
                signIn(with: email)
            }
        }
    }
    
    
    // MARK: - Fetch user profile data
    func fetchUserProfile() {
        isLoading = true
        finishedLoadingProfile = false

        guard let uid = userSession?.uid else {
            isLoading = false
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.finishedLoadingProfile = true
                    self.isLoggedIn = false
                }
                return
            }

            guard let data = snapshot?.data() else {
                DispatchQueue.main.async {
                    self.finishedLoadingProfile = true
                    self.isLoggedIn = false
                }
                return
            }

            DispatchQueue.main.async {
                self.username = data["username"] as? String

                let flavorRaw = data["flavorText"]
                let classRaw = data["npcClass"]

                let flavorStr = (flavorRaw as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let classStr = (classRaw as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

                self.flavorText = (flavorStr?.isEmpty ?? true || flavorStr == "null") ? nil : flavorStr
                self.characterClass = (classStr?.isEmpty ?? true || classStr == "null") ? nil : classStr

                self.userXP = data["xp"] as? Int ?? 0
                self.userLevel = data["level"] as? Int ?? 1
                self.needsOnboarding = (self.flavorText == nil || self.characterClass == nil)

                self.isLoggedIn = true
                self.finishedLoadingProfile = true

//                print("🧠 flavorText:", self.flavorText ?? "nil")
//                print("🧠 characterClass:", self.characterClass ?? "nil")
//                print("🧠 needsOnboarding:", self.needsOnboarding)
            }
        }
    }


    // =============================
    // ===== DAILY QUEST STUFF =====
    // =============================
    func checkOrGenerateDailyQuest() {
        print("Called checkOrGenerateDailyQuest()")
        guard userSession != nil, isLoggedIn else {
            self.dailyQuest = nil
            return
        }
        
        guard let userFlavor = flavorText, !userFlavor.isEmpty,
              let userClass = characterClass, !userClass.isEmpty else {
            print("Waiting for flavorText and characterClass before generating daily quest")
            return
        }
        
        let todayKey = self.currentDailyQuestKey()
        let statusKey = self.todayStatusKey()
        let status = UserDefaults.standard.string(forKey: statusKey) ?? "pending"
        if status == "accepted" || status == "discarded" {
            self.dailyQuest = nil
            print("Daily quest already accepted or discarded: \(status)")
            return
        }
        if let saved = UserDefaults.standard.data(forKey: todayKey),
           let quest = try? JSONDecoder().decode(Quest.self, from: saved) {
            self.dailyQuest = quest
            print("Loaded daily quest from UserDefaults: \(quest.title)")
            return
        }
        print("Generating daily quest with flavor: '\(userFlavor)' and class: '\(userClass)'")
        OpenAIService.shared.generateDailyQuest(flavor: userFlavor, userClass: userClass) { [weak self] questDesc in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let quest = Quest(
                    id: nil,
                    title: "Daily Quest",
                    flavored: questDesc ?? "Start your day with an act of magic!",
                    xp: Int.random(in: 10...30),
                    recommendedClass: userClass,
                    completed: false,
                    subtasks: nil,
                    timestamp: Date(),
                    isDaily: true
                )
                self.dailyQuest = quest
                if let encoded = try? JSONEncoder().encode(quest) {
                    UserDefaults.standard.set(encoded, forKey: todayKey)
                }
                UserDefaults.standard.set("pending", forKey: statusKey)
            }
        }
    }
    
    func acceptDailyQuest() {
        guard let quest = self.dailyQuest else { return }
        var accepted = quest
        accepted.isDaily = true
        self.saveQuest(accepted) { _ in }
        self.dailyQuest = nil
        let todayKey = self.currentDailyQuestKey()
        let statusKey = self.todayStatusKey()
        if let encoded = try? JSONEncoder().encode(quest) {
            UserDefaults.standard.set(encoded, forKey: todayKey)
        }
        UserDefaults.standard.set("accepted", forKey: statusKey)
    }
    func discardDailyQuest() {
        self.dailyQuest = nil
        let statusKey = self.todayStatusKey()
        UserDefaults.standard.set("discarded", forKey: statusKey)
    }
    func refreshForNewDay() {
        let statusKey = self.todayStatusKey()
        UserDefaults.standard.set("pending", forKey: statusKey)
        self.checkOrGenerateDailyQuest()
    }
    
    // MARK: - XP and Level Up
    func xpForNextLevel(_ level: Int) -> Int {
        // Linear scaling (customize for your game)
        return 50 + (level - 1) * 50
    }
    
    func addXP(_ amount: Int) {
        var xp = userXP + amount
        var level = userLevel
        var leveledUp = false
        while xp >= xpForNextLevel(level) {
            xp -= xpForNextLevel(level)
            level += 1
            leveledUp = true
        }
        userXP = xp
        userLevel = level
        saveXPAndLevelToFirestore()
        if leveledUp {
            DispatchQueue.main.async {
                self.didLevelUp = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.didLevelUp = false
            }
        }
    }
    func saveXPAndLevelToFirestore() {
        guard let uid = userSession?.uid else { return }
        db.collection("users").document(uid).updateData([
            "xp": userXP,
            "level": userLevel
        ])
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userSession = nil
                self.flavorText = nil
                self.characterClass = nil
                self.username = nil
                self.isLoggedIn = false
                self.errorMessage = nil
                self.quests = []
                self.completedQuests = []
                self.dailyQuest = nil
                self.userXP = 0
                self.userLevel = 1
                self.didLevelUp = false
                self.isLoading = false
                self.isProfileLoading = false
                self.finishedLoadingProfile = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Sign out failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
        
    }
}
