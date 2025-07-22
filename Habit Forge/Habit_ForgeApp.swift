//
//  Habit_ForgeApp.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/21/25.
//

import SwiftUI
import Firebase
@main
struct Habit_ForgeApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
