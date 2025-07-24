//
//  LoginView.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/24/25.
//

import SwiftUI
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var loginInput: String = ""
    @State private var password: String = ""
    
    var body: some View{
        VStack(spacing:20){
            Text("Log In")
                .font(.largeTitle)
                .bold()
            
            TextField("Username or email", text:$loginInput)
                
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password",text:$password)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
            
            if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty{
                Text(errorMessage)
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
            }
            Button("Log In"){
                authViewModel.login(identifier: loginInput, password: password){ result in
                    switch result {
                    case .success:
                        //login sucessful
                        break
                        
                    case .failure(let error):
                        print("Login failed: \(error.localizedDescription)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authViewModel.isLoading)
        
            
        }
        .padding()
    }
    }

