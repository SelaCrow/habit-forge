import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    var onCancel: () -> Void
    
    var body: some View {
        ZStack{
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
            
                
                Button(action: {
                    authViewModel.isLoading = true
                    authViewModel.signUp(username: username, email: email, password: password) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                username = ""
                                email = ""
                                password = ""
                                // Do NOT set isLoading = false here
                                // Let ContentView handle hiding the splash
                            case .failure(let error):
                                authViewModel.errorMessage = error.localizedDescription
                                authViewModel.isLoading = false // Only stop loading on
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    authViewModel.errorMessage = nil
                                }
                            }
                        }
                    }
                })
                {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image("Sign_up")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 90)
                    }
                }
                .disabled(username.isEmpty || email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .opacity((username.isEmpty || email.isEmpty || password.isEmpty || authViewModel.isLoading) ? 0.5 : 1)
                
                
                
                Button(action: {
                    authViewModel.errorMessage = nil  // Clear the error instantly
                    onCancel()
                }){
                    Image("cancel_btn")
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 60)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 10)
            }
            .padding(.top, 170) // push down from very top of screen
            .frame(maxHeight: .infinity, alignment: .top)
            
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .zIndex(1)
                    .animation(.easeInOut(duration: 0.25), value: authViewModel.errorMessage)
            }
        }
        
    }
}
