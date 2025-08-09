import SwiftUI
import UIKit

// MARK: - Text helpers
import SwiftUI
import UIKit

func splitQuest(_ fullText: String) -> (String, String) {
    let delimiters: [Character] = [".", "!", "?", ":"]
    if let index = fullText.firstIndex(where: { delimiters.contains($0) }) {
        let titleRange = fullText.startIndex...index
        var title = String(fullText[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.hasSuffix(":") {
            title = title.trimmingCharacters(in: .whitespaces)
            if !title.hasSuffix(".") && !title.hasSuffix("!") && !title.hasSuffix("?") {
                title += ":"
            }
        }
        let descriptionStart = fullText.index(after: index)
        let desc = String(fullText[descriptionStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (title, desc)
    } else {
        return (fullText, "")
    }
}

func extractDescriptionFallback(from text: String) -> String {
    let components = text.components(separatedBy: ". ")
    if components.count > 1 {
        return components.dropFirst().joined(separator: ". ")
    } else {
        return text
    }
}

private func themedImageName(_ baseName: String, flavorText: String?) -> String {
    if baseName.hasPrefix("level_up") { return baseName }
    let isSci = (flavorText ?? "").lowercased().contains("sci")
    if baseName.hasPrefix("pen_loading_animation") {
        guard isSci else { return baseName }
        let prefix = "pen_loading_animation"
        let suffix = baseName.dropFirst(prefix.count)
        let candidate = "scifi_generating_quest_animation\(suffix)"
        return UIImage(named: candidate) != nil ? candidate : baseName
    }
    if isSci {
        let candidate = "scifi_\(baseName)"
        return UIImage(named: candidate) != nil ? candidate : baseName
    }
    return baseName
}

struct QuestBoardView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @State private var loadingFrame = 1
    private let defaultLoadingFrames = 30
    private var loadingTotalFrames: Int {
        (authViewModel.flavorText ?? "").lowercased().contains("sci") ? 31 : defaultLoadingFrames
    }
    let animationSpeed = 0.08
    let pixelLoadingTimer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

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
                    WelcomeHeader(username: authViewModel.username,
                                  characterClass: authViewModel.characterClass,
                                  flavorText: authViewModel.flavorText)

                    LevelRow(userLevel: authViewModel.userLevel,
                             userXP: authViewModel.userXP,
                             totalXP: authViewModel.xpForNextLevel(authViewModel.userLevel),
                             flavorText: authViewModel.flavorText)

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
                            discard: { authViewModel.discardDailyQuest() },
                            flavorText: authViewModel.flavorText
                        )
                        .id("dailyQuest")
                        .padding(.top, -20)
                    }

                    QuestInput(userTask: $userTask,
                               isLoadingQuest: $isLoadingQuest,
                               flavorText: authViewModel.flavorText,
                               characterClass: authViewModel.characterClass,
                               onQuestGenerated: { flavored in
                        let quest = Quest(
                            id: nil,
                            title: userTask,
                            flavored: flavored ?? "No quest generated.",
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
                    })

                    QuestList(quests: authViewModel.quests,
                              expandedQuestID: $expandedQuestID,
                              flavorText: authViewModel.flavorText,
                              complete: { id in authViewModel.completeQuest(questID: id) },
                              delete: { id in authViewModel.deleteQuest(questID: id) })

                    SignOutButton(flavorText: authViewModel.flavorText) {
                        authViewModel.signOut()
                    }
                }
                .onChange(of: authViewModel.dailyQuest) { _, newValue in
                    if newValue != nil &&
                        UserDefaults.standard.string(forKey: authViewModel.todayStatusKey()) != "discarded" &&
                        !lockInDailyQuest {
                        withAnimation { animateDailyQuest = true }
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

            if authViewModel.didLevelUp {
                LevelUpPopup()
                    .environmentObject(authViewModel)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { authViewModel.didLevelUp = false }
                        }
                    }
            }
        }
        .overlay(
            loadingOverlay
                .opacity(isLoadingQuest ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isLoadingQuest)
        )
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            Image(themedImageName("pen_loading_animation\(loadingFrame)", flavorText: authViewModel.flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 1000, height: 800)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(pixelLoadingTimer) { _ in
            loadingFrame = loadingFrame % loadingTotalFrames + 1
        }
        .zIndex(99)
    }
}

struct WelcomeHeader: View {
    let username: String?
    let characterClass: String?
    let flavorText: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(themedImageName("welcome_guest_box", flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(height: 80)
                .clipped()

            HStack(spacing: 15) {
                Text("Welcome,")
                    .font(.custom("ThaleahFat", size: 36))
                Text(username ?? "Adventurer")
                    .font(.custom("ThaleahFat", size: 36))
                    .padding(.top, 2)
            }
            .bold()
            .foregroundStyle(Color.white)
            .padding(.top, 20)
            .padding(.leading, 20)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            ZStack {
                Image(themedImageName("header_class_level", flavorText: flavorText))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 50)
                    .clipped()

                Text("\(characterClass ?? "None")")
                    .font(.custom("ThaleahFat", size: 16))
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                    .padding(.top, 1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 160)
            .offset(x: 14, y: 50)
        }
        .padding(.top, 40)
        .padding(.bottom, 5)
    }
}

struct LevelRow: View {
    let userLevel: Int
    let userXP: Int
    let totalXP: Int
    let flavorText: String?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(themedImageName("level", flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(height: 14)
                .padding(.leading, 10)

            Text("\(userLevel)")
                .font(.custom("ThaleahFat", size: 36))
                .bold()
                .foregroundColor(.yellow)

            ZStack {
                Image(themedImageName("level_bar_decoration", flavorText: flavorText))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 16)
                    .frame(maxWidth: 405)
                    .padding(.leading, 25)

                ProgressView(value: Double(userXP), total: Double(totalXP))
                    .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                    .frame(height: 10)
                    .padding(.leading, 25)
                    .frame(maxWidth: 400)
            }

            Text("\(userXP) / \(totalXP) XP")
                .font(.custom("ThaleahFat", size: 16))
                .foregroundColor(.white)
                .padding(.trailing, 20)
        }
        .padding(.leading, 12)
    }
}

struct QuestInput: View {
    @Binding var userTask: String
    @Binding var isLoadingQuest: Bool
    let flavorText: String?
    let characterClass: String?
    let onQuestGenerated: (String?) -> Void

    var body: some View {
        ZStack {
            Image(themedImageName("add_quest_background", flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()

            VStack(spacing: 10) {
                Image(themedImageName("add_quest", flavorText: flavorText))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 40)
                    .padding(.top, -40)

                ZStack(alignment: .leading) {
                    Image(themedImageName("add_quest_text_box", flavorText: flavorText))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 45)
                        .offset(x: 14, y: -5)

                    TextField("Enter your task...", text: $userTask)
                        .padding(.leading, 25)
                        .padding(.trailing, 60)
                        .padding(.vertical, 2)
                        .foregroundColor(.black)
                        .disableAutocorrection(true)
                        .onSubmit(submit)
                }
            }
            .padding(.horizontal)
            .frame(height: 60)
            .padding(.vertical, 10)
        }
        .padding(.bottom, 20)
    }

    private func submit() {
        guard !userTask.isEmpty else { return }
        isLoadingQuest = true
        let flavor = flavorText ?? "fantasy"
        let userClass = characterClass ?? "Adventurer"
        OpenAIService.shared.flavorizeQuest(task: userTask, flavor: flavor, userClass: userClass) { questDesc in
            DispatchQueue.main.async {
                onQuestGenerated(questDesc)
            }
        }
    }
}

struct QuestList: View {
    let quests: [Quest]
    @Binding var expandedQuestID: String?
    let flavorText: String?
    let complete: (String) -> Void
    let delete: (String) -> Void

    var body: some View {
        ZStack {
            Image(themedImageName("your_quest_board", flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()

            ScrollView {
                VStack(spacing: 0) {
                    if quests.isEmpty {
                        Text("No quests yet. Add a new quest!")
                            .foregroundColor(.white)
                            .padding(.top, 40)
                    } else {
                        ForEach(quests) { quest in
                            QuestRow(quest: quest,
                                     isExpanded: expandedQuestID == quest.id,
                                     expand: { withAnimation(.easeInOut) { expandedQuestID = quest.id } },
                                     collapse: { withAnimation(.easeInOut) { expandedQuestID = nil } },
                                     flavorText: flavorText,
                                     complete: complete,
                                     delete: delete)
                            .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.top, 40)
            }
            .frame(height: 350)
        }
    }
}

struct QuestRow: View {
    let quest: Quest
    let isExpanded: Bool
    let expand: () -> Void
    let collapse: () -> Void
    let flavorText: String?
    let complete: (String) -> Void
    let delete: (String) -> Void

    var body: some View {
        let (title, description) = splitQuest(quest.flavored)
        let fallbackDesc = description.isEmpty ? extractDescriptionFallback(from: quest.flavored) : description

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(themedImageName("quest_title_box", flavorText: flavorText))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 100)

                VStack {
                    HStack(alignment: .top) {
                        Text(title)
                            .font(.custom("ThaleahFat", size: 17))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .padding(.leading, 12)
                            .padding(.top, 32)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        if !isExpanded {
                            HStack(spacing: -10) {
                                if !quest.completed, let id = quest.id {
                                    Button { complete(id) } label: {
                                        Image(themedImageName("complete_button", flavorText: flavorText))
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 80, height: 30)
                                    }
                                }
                                if let id = quest.id {
                                    Button { delete(id) } label: {
                                        Image(themedImageName("delete_button", flavorText: flavorText))
                                            .resizable()
                                            .interpolation(.none)
                                            .scaledToFit()
                                            .frame(width: 80, height: 30)
                                            .offset(x: -12)
                                    }
                                }
                            }
                            .padding(.top, 40)
                            .padding(.leading, 12)
                        }
                    }

                    if !isExpanded {
                        Button(action: expand) {
                            Image(systemName: "chevron.down")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.purple)
                                .offset(y: -12)
                                .shadow(color: .white, radius: 0, x: 1, y: 1)
                                .shadow(color: .white, radius: 0, x: -1, y: 1)
                                .shadow(color: .white, radius: 0, x: 1, y: -1)
                                .shadow(color: .white, radius: 0, x: -1, y: -1)

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

            if isExpanded {
                ZStack(alignment: .topLeading) {
                    Image(themedImageName("quest_description_box", flavorText: flavorText))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(fallbackDesc)
                            .font(.custom("ThaleahFat", size: 16))
                            .foregroundColor(.black)
                            .padding(.top, 12)
                            .padding(.horizontal, 12)

                        HStack(spacing: 10) {
                            Text("XP: \(quest.xp)")
                                .foregroundColor(.orange)
                                .font(.custom("ThaleahFat", size: 14))

                            if let cls = quest.recommendedClass {
                                Text("Class: \(cls)")
                                    .font(.custom("ThaleahFat", size: 14))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                            }

                            if quest.completed {
                                Text("Completed")
                                    .foregroundColor(.green)
                                    .font(.custom("ThaleahFat", size: 14))
                            }

                            Spacer()

                            if !quest.completed, let id = quest.id {
                                Button { complete(id) } label: {
                                    Image(themedImageName("complete_button", flavorText: flavorText))
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 80, height: 30)
                                }
                            }

                            if let id = quest.id {
                                Button { delete(id) } label: {
                                    Image(themedImageName("delete_button", flavorText: flavorText))
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 80, height: 30)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Button(action: collapse) {
                            Image(systemName: "chevron.up")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.purple)
                            .shadow(color: .white, radius: 0, x: 1, y: 1)
                            .shadow(color: .white, radius: 0, x: -1, y: 1)
                            .shadow(color: .white, radius: 0, x: 1, y: -1)
                            .shadow(color: .white, radius: 0, x: -1, y: -1)

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 12)
                    }
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: isExpanded)
            }
        }
    }
}

struct DailyQuestCard: View {
    let daily: Quest
    let isExpanded: Bool
    let toggleExpanded: () -> Void
    var accept: () -> Void
    var discard: () -> Void
    let flavorText: String?

    var body: some View {
        let (flavorTitle, flavorDesc) = splitQuest(daily.flavored)

        ZStack {
            Image(themedImageName(isExpanded ? "daily_quest_extended_paper" : "daily_quest_background",
                                  flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .transition(.opacity)

            VStack(spacing: 12) {
                Image(themedImageName("daily_quest", flavorText: flavorText))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 40)
                    .offset(y: 20)
                    .zIndex(1)

                Button(action: toggleExpanded) {
                    ZStack {
                        Image(themedImageName("daily_quest_box", flavorText: flavorText))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(height: 50)

                        HStack {
                            Text(flavorTitle)
                                .font(.custom("ThaleahFat", size: 18))
                                .foregroundColor(.black)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.purple)
                                .padding(.trailing, 15)
                                .shadow(color: .white, radius: 0, x: 1, y: 1)
                                .shadow(color: .white, radius: 0, x: -1, y: 1)
                                .shadow(color: .white, radius: 0, x: 1, y: -1)
                                .shadow(color: .white, radius: 0, x: -1, y: -1)

                        }
                        .padding(.horizontal)
                    }
                }

                if isExpanded && !flavorDesc.isEmpty {
                    ZStack(alignment: .topLeading) {
                        Image(themedImageName("hover_paper_box", flavorText: flavorText))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(maxWidth: .infinity)

                        Text(flavorDesc)
                            .font(.custom("ThaleahFat", size: 20))
                            .foregroundColor(.black)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                ZStack {
                    Image(themedImageName("daily_quest_class_box", flavorText: flavorText))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 65)

                    VStack {
                        Text("XP: \(daily.xp)")
                            .font(.custom("ThaleahFat", size: 18))
                            .foregroundColor(.white)

                        if let cls = daily.recommendedClass {
                            Text(" \(cls)")
                                .font(.custom("ThaleahFat", size: 15))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.bottom, 10)
                }

                HStack(spacing: 20) {
                    Button(action: accept) {
                        Image(themedImageName("accept_button", flavorText: flavorText))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 90, height: 40)
                    }
                    Button(action: discard) {
                        Image(themedImageName("discard_button", flavorText: flavorText))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 90, height: 40)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

struct LevelUpPopup: View {
    @State private var currentFrame = 1
    let totalFrames = 45
    let frameDuration = 0.05
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                Image("level_up\(currentFrame)")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 1000, height: 800)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .onAppear { playAnimationOnce() }
        }
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
        .allowsHitTesting(false)
    }

    private func playAnimationOnce() {
        for i in 1...totalFrames {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i - 1) * frameDuration)) {
                currentFrame = i
            }
        }
        let totalDuration = Double(totalFrames) * frameDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                authViewModel.didLevelUp = false
            }
        }
    }
}
struct SignOutButton: View {
    let flavorText: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(themedImageName("sign_out", flavorText: flavorText))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 120, height: 60)
                .padding(.bottom, 30)
                .padding(.leading, 30)
        }
    }
}
