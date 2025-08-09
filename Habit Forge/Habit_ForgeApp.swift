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
        for family in UIFont.familyNames {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, .custom("ThaleahFat", size: 24))
        }
    }
}
