//
//  Quest.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/27/25.
//

import Foundation




// Main Quest data model for your app/Firestore
struct Quest: Identifiable, Codable, Equatable  {
    var id: String?              // Firestore document ID (can be nil for new quests)
    var title: String            // User's raw input
    var flavored: String         // AI-generated description
    var xp: Int
    var recommendedClass: String?
    var completed: Bool
    var subtasks: [String]?
    var timestamp: Date
    var isDaily: Bool = false
}
