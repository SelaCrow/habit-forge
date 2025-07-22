//
//  AuthViewModel.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/21/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject{
    @Published var user: User?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    init(){
        self.user = Auth.auth().currentUser
    }
    func signInAnonymously(){
        isLoading = true
        Auth.auth().signInAnonymously{[weak self] authResult, error in
            DispatchQueue.main.async{
                self?.isLoading = false
                if let error = error {
                    print("Anon login error")
                    return
                }
                guard let user = authResult?.user else {return}
                self?.user = user
                self?.createUserProfileIfNeeded(userID: user.uid)
                
            }
        }
    }
    private func createUserProfileIfNeeded(userID: String){
        let userRef = db.collection("users").document(userID)
        userRef.getDocument{ document, error in
            if let document = document, document.exists {
                print("User profile already exists.")
            } else {
                userRef.setData([
                    "xp":0,
                    "level":1,
                    "class":"Unassigned",
                    "createdAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error{
                        print("error creating profile")
                    } else {
                        print("User profile created!")
                    }
                    
                }
            }
        }
    }
    func signOut(){
        do{
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("Sign out error")
        }
    }
}
