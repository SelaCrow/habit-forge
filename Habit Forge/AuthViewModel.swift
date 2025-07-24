import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?  // Current Firebase user session
    @Published var isLoggedIn = false                // Login state flag
    @Published var errorMessage: String?             // For error messages to show in UI
    @Published var isLoading = false                  // Shows loading indicator during async tasks

    private var db = Firestore.firestore()           // Firestore database reference

    init() {
        // Initialize user session and login status on startup
        self.userSession = Auth.auth().currentUser
        self.isLoggedIn = userSession != nil
    }

    // MARK: - Sign Up with username, email, password
    func signUp(username: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        // Check if username already exists in Firestore
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
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
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Sign-up failed: \(error.localizedDescription)"
                        completion(.failure(error))
                    }
                    return
                }

                guard let user = result?.user else {
                    let unknownError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error during user creation."])
                    DispatchQueue.main.async {
                        completion(.failure(unknownError))
                    }
                    return
                }

                // Update user session and login state on main thread
                DispatchQueue.main.async {
                    self.userSession = user
                    self.isLoggedIn = true
                }

                // Save user profile data to Firestore
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": email,
                    "username": username
                ]

                self.db.collection("users").document(user.uid).setData(userData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                            completion(.failure(error))
                        } else {
                            self.errorMessage = nil
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Anonymous Sign In
    func signInAnonymously() {
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.userSession = result?.user
                self?.isLoggedIn = true
            }
        }
    }
// MARK: - Log in
    func login(identifier: String, password: String, completion: @escaping(Result<Void,Error>) -> Void) {
        isLoading = true

        func signIn(with email: String) {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    self.isLoading = false

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
                    completion(.success(()))
                }
            }
        }

        // Check if input is email or username
        if identifier.contains("@") {
            // assume email
            signIn(with: identifier)
        } else {
            // assume username
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
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userSession = nil
                self.isLoggedIn = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Sign out failed: \(error.localizedDescription)"
            }
        }
    }
}
