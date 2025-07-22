//
//  ContentView.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/21/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    var body: some View {
        VStack(spacing: 20){
            if let user = authVM.user{
                Text("Welcome, Adventurer!")
                    .font(.title)
                Text("Your UID: \(user.uid.prefix(6))...")
                    .font(.subheadline)
                Button("Sign Out"){
                    authVM.signOut()
                }
                .padding()
            }
            else {
                if authVM.isLoading{
                    ProgressView()
                }
                else {
                    Button("Start as Guest"){
                        authVM.signInAnonymously()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }        }
        .padding()
    }
}

#Preview {
    ContentView()
}
