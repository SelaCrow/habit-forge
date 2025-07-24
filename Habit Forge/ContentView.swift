import SwiftUI

struct ContentView: View {
    // Initialize the AuthViewModel and observe its published properties
    @StateObject private var authViewModel = AuthViewModel()
    
    // Controls whether the sign-up form is visible
    @State private var showSignUpForm = false
    @State private var showLoginForm = false

    var body: some View {
        VStack(spacing: 20) {
            
            // If the user is logged in, show welcome message and sign out button
            if let user = authViewModel.userSession {
                Text("Welcome, Adventurer!")
                    .font(.title)
                Text("Your UID: \(user.uid.prefix(6))...")  // Show part of UID
                    .font(.subheadline)
                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .padding()
            } else {
                // User is not logged in
                
                if authViewModel.isLoading {
                    // Show a progress spinner while loading
                    ProgressView()
                } else {
                    // Show a button to toggle the sign-up form
                    Button(showSignUpForm ? "Cancel Sign Up" : "Sign Up") {
                        withAnimation {
                            showSignUpForm.toggle()  // Show or hide the SignUpView
                            if !showSignUpForm {
                                authViewModel.errorMessage = nil
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                  
                    Button(showLoginForm ? "Cancel Login":"Login"){
                        withAnimation{
                            showLoginForm.toggle()
                            if !showLoginForm{
                                authViewModel.errorMessage = nil
                            }
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(Color.white)
                    .cornerRadius(8)
                    
                    if showLoginForm{
                        LoginView()
                            .environmentObject(authViewModel)
                            .transition(.slide)
                    }
                    // If toggled, show the SignUpView and pass the authViewModel environment object
                    if showSignUpForm {
                        SignUpView()
                            .environmentObject(authViewModel)
                            .transition(.slide)  // Animate form appearing/disappearing
                    }
                    
                    // Always show a button for anonymous guest login
                    Button("Start as Guest") {
                        authViewModel.signInAnonymously()
                    }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Show any authentication error messages below the buttons
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
