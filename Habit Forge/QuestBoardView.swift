import SwiftUI

func splitQuest(_ fullText: String) -> (String, String) {
    let parts = fullText.components(separatedBy: "\n\n")
    let title = parts.first ?? fullText
    let desc = parts.dropFirst().joined(separator: "\n\n")
    return (title, desc)
}
func extractDescriptionFallback(from text: String) -> String {
    let components = text.components(separatedBy: ". ")
    if components.count > 1 {
        return components.dropFirst().joined(separator: ". ")
    } else {
        return text // fallback if it’s just one sentence
    }
}

struct QuestBoardView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @State private var userTask = ""
    @State private var isLoadingQuest = false
    @State private var expandedQuestID: String? = nil
    @State private var showLevelUpPopup = false

    @State private var animateDailyQuest = false
    @State private var lockInDailyQuest = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome area
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome, \(authViewModel.username ?? "Adventurer")!")
                            .font(.title)
                            .bold()
                        Text("Class: \(authViewModel.characterClass ?? "None")")
                            .font(.subheadline)
                    }

                    // Level and XP
                    HStack(spacing: 16) {
                        Text("Level \(authViewModel.userLevel)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.yellow)
                        ProgressView(
                            value: Double(authViewModel.userXP),
                            total: Double(authViewModel.xpForNextLevel(authViewModel.userLevel))
                        )
                        .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                        .frame(height: 10)
                        .frame(maxWidth: 150)
                        Text("\(authViewModel.userXP) / \(authViewModel.xpForNextLevel(authViewModel.userLevel)) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    // Docked Daily Quest Card
                    if lockInDailyQuest,
                       let daily = authViewModel.dailyQuest,
                       UserDefaults.standard.string(forKey: authViewModel.todayStatusKey()) != "discarded" {
                        DailyQuestCard(
                            daily: daily,
                            isExpanded: expandedQuestID == "dailyQuest",
                            toggleExpanded: {
                                withAnimation {
                                    expandedQuestID = expandedQuestID == "dailyQuest" ? nil : "dailyQuest"
                                }
                            },
                            accept: { authViewModel.acceptDailyQuest() },
                            discard: { authViewModel.discardDailyQuest() }
                        )
                        .id("dailyQuest")
                    }

                    // Quest Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a Quest")
                            .font(.headline)
                        TextField("Enter your task...", text: $userTask)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onSubmit {
                                guard !userTask.isEmpty else { return }
                                isLoadingQuest = true
                                let flavor = authViewModel.flavorText ?? "fantasy"
                                let userClass = authViewModel.characterClass ?? "Adventurer"
                                OpenAIService.shared.flavorizeQuest(
                                    task: userTask,
                                    flavor: flavor,
                                    userClass: userClass
                                ) { questDesc in
                                    DispatchQueue.main.async {
                                        let quest = Quest(
                                            id: nil,
                                            title: userTask,
                                            flavored: questDesc ?? "No quest generated.",
                                            xp: Int.random(in: 5...20),
                                            recommendedClass: authViewModel.characterClass,
                                            completed: false,
                                            subtasks: nil,
                                            timestamp: Date()
                                        )
                                        authViewModel.saveQuest(quest) { _ in
                                            userTask = ""
                                            isLoadingQuest = false
                                        }
                                    }
                                }
                            }
                        if isLoadingQuest {
                            ProgressView("Generating quest...")
                        }
                    }
                    .padding(.bottom, 20)

                    // Quest Board List
                    Text("Your Quest Board")
                        .font(.headline)

                    if authViewModel.quests.isEmpty {
                        Text("No quests yet. Add a new quest!")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(authViewModel.quests) { quest in
                            VStack(alignment: .leading, spacing: 4) {
                                // 🧠 Smart splitting logic
                                let (title, description) = splitQuest(quest.flavored)
                                let fallbackDesc = description.isEmpty ? extractDescriptionFallback(from: quest.flavored) : description

                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        expandedQuestID = expandedQuestID == quest.id ? nil : quest.id
                                    }
                                }) {
                                    HStack {
                                        Text(title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .rotationEffect(.degrees(expandedQuestID == quest.id ? 180 : 0))
                                            .foregroundColor(.purple)
                                            .animation(.easeInOut(duration: 0.25), value: expandedQuestID)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color.purple.opacity(0.12))
                                    .cornerRadius(8)
                                }

                                if expandedQuestID == quest.id {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(fallbackDesc)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                            .animation(.easeInOut, value: expandedQuestID)

                                        HStack(spacing: 10) {
                                            Text("XP: \(quest.xp)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            if let cls = quest.recommendedClass {
                                                Text("Class: \(cls)")
                                                    .font(.caption2)
                                                    .foregroundColor(.purple)
                                            }
                                            if quest.completed {
                                                Text("Completed")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                            }
                                            Spacer()
                                            if !quest.completed {
                                                Button("Complete") {
                                                    if let id = quest.id {
                                                        authViewModel.completeQuest(questID: id)
                                                    }
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            }
                                            Button("Delete") {
                                                if let id = quest.id {
                                                    authViewModel.deleteQuest(questID: id)
                                                }
                                            }
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.vertical, 5)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .animation(.easeInOut, value: expandedQuestID)
                        }
                    }


                    Spacer()
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .padding(.top, 20)
                }
                .padding()
            }

            // Floating animated Daily Quest
//            if animateDailyQuest,
//               let daily = authViewModel.dailyQuest,
//               UserDefaults.standard.string(forKey: authViewModel.todayStatusKey()) != "discarded" {
//                VStack {
//                    DailyQuestCard(
//                        daily: daily,
//                        isExpanded: expandedQuestID == "dailyQuest",
//                        toggleExpanded: {
//                            withAnimation {
//                                expandedQuestID = expandedQuestID == "dailyQuest" ? nil : "dailyQuest"
//                            }
//                        },
//                        accept: { authViewModel.acceptDailyQuest() },
//                        discard: { authViewModel.discardDailyQuest() }
//                    )
//                    Spacer()
//                }
//                .padding(.horizontal)
//                .transition(.move(edge: .top).combined(with: .opacity))
//                .zIndex(1)
//            }

            // Level Up Popup
            if authViewModel.didLevelUp {
                LevelUpPopup()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                authViewModel.didLevelUp = false
                            }
                        }
                    }
            }
        }
        .onChange(of: authViewModel.dailyQuest) { oldValue, newValue in
            if newValue != nil &&
                UserDefaults.standard.string(forKey: authViewModel.todayStatusKey()) != "discarded" &&
                !lockInDailyQuest {
                withAnimation {
                    animateDailyQuest = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        lockInDailyQuest = true
                        animateDailyQuest = false
                    }
                }
            }
        }
        .animation(.spring(), value: authViewModel.didLevelUp)
    }
}

struct DailyQuestCard: View {
    let daily: Quest
    let isExpanded: Bool
    let toggleExpanded: () -> Void
    var accept: () -> Void
    var discard: () -> Void

    var body: some View {
        let (flavorTitle, flavorDesc) = splitQuest(daily.flavored)
        VStack(alignment: .leading, spacing: 4) {
            Text("🌞 Daily Quest")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 2)
            Button(action: toggleExpanded) {
                HStack {
                    Text("🌟 " + flavorTitle)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color.blue.opacity(0.14))
                .cornerRadius(8)
            }
            if isExpanded && !flavorDesc.isEmpty {
                Text(flavorDesc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .transition(.opacity)
            }
            HStack(spacing: 10) {
                Text("XP: \(daily.xp)")
                    .font(.caption)
                    .foregroundColor(.orange)
                if let cls = daily.recommendedClass {
                    Text("Class: \(cls)")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
                Spacer()
                Button("Accept", action: accept)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Button("Discard", action: discard)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.bottom, 12)
    }

}

struct LevelUpPopup: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                        .shadow(radius: 10)
                    Text("Level Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .shadow(radius: 2)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(radius: 20)
                Spacer()
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
}
