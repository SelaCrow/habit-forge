import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if authViewModel.isLoading {
                ProgressView()
            } else {
                Button("Sign Up") {
                    authViewModel.signUp(username: username, email: email, password: password) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                errorMessage = ""
                                // Optionally clear input fields after success
                                username = ""
                                email = ""
                                password = ""
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || email.isEmpty || password.isEmpty)
            }
        }
        .padding()
    }
}
