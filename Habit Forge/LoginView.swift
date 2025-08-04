import SwiftUI

struct LoginView: View {
    @State private var identifier = ""  // Username or Email
    @State private var password = ""

    @EnvironmentObject var authViewModel: AuthViewModel
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email or Username", text: $identifier)
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
                    authViewModel.login(identifier: identifier, password: password) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                identifier = ""
                                password = ""
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
                        Image("log_in")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 90)
                            .opacity((identifier.isEmpty || password.isEmpty || authViewModel.isLoading) ? 0.5 : 1.0)
                    }
                }
                .disabled(identifier.isEmpty || password.isEmpty || authViewModel.isLoading)

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
        .padding()
        .frame(height: 500)
    }
}
