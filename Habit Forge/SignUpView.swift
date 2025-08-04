import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var authViewModel: AuthViewModel
    var onCancel: () -> Void


    var body: some View {
        VStack {
            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .padding(.horizontal, 12)
                    .frame(width: 300, height: 70)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 12)
                    .frame(width: 300, height: 70)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

                SecureField("Password", text: $password)
                    .padding(.horizontal, 12)
                    .frame(width: 300, height: 70)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(action: {
                        authViewModel.isLoading = true
                        

                        authViewModel.signUp(username: username, email: email, password: password) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    username = ""
                                    email = ""
                                    password = ""
                                    authViewModel.flavorText = nil
                                    authViewModel.characterClass = nil
                                    authViewModel.needsOnboarding = true
                                    authViewModel.fetchUserProfile() // ✅ Trigger profile fetch here
                                case .failure(let error):
                                    authViewModel.errorMessage = error.localizedDescription
                                    
                                }
                                authViewModel.isLoading = false
                            }
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image("Sign_up")
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 90)
                                .opacity((username.isEmpty || email.isEmpty || password.isEmpty || authViewModel.isLoading) ? 0.5 : 1.0)
                        }
                    }
                    .disabled(username.isEmpty || email.isEmpty || password.isEmpty || authViewModel.isLoading)

                    Button(action: onCancel) {
                        Image("cancel_btn")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 60)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, -80)
        }
        .padding()
        .frame(height: 500)
    }
}

