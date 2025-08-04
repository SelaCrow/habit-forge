import SwiftUI

struct ClassSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Callback triggered after a class is selected (e.g., to show splash)
    var onClassSelected: () -> Void = {}

    let fantasyClasses = [
        "Coffee Bar Mage",
        "Commuter Bard",
        "Laundry Paladin",
        "Errand Ranger",
        "Study Sorcerer",
        "Zoom Druid",
        "Gym Barbarian",
        "Kitchen Cleric"
    ]

    let sciFiClasses = [
        "Space Engineer",
        "Cybernetic Hacker",
        "Quantum Pilot",
        "Nano Medic",
        "Galactic Trader",
        "Android Operative",
        "Laser Ranger",
        "Stellar Navigator"
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 20) {
                    Image("choose_a_class")
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 80)

                    let classes = (authViewModel.flavorText == "sci-fi") ? sciFiClasses : fantasyClasses

                    ForEach(classes, id: \.self) { npcClass in
                        VStack(spacing: 10) {
                            Text(npcClass)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(12)

                            Button("Confirm Class") {
                                authViewModel.updateUserProfile(field: "npcClass", value: npcClass) {
                                    DispatchQueue.main.async {
                                        authViewModel.needsOnboarding = false
                                        onClassSelected() // ✅ Trigger splash from ContentView
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding()
            }
        }
    }
}
