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
                        let buttonImage = authViewModel.flavorText == "sci-fi" ? "scifi_class_button" : "fantasy_class_button"
                        
                        ScrollView {
                            VStack(spacing: 40) {
                                ForEach(classes, id: \.self) { npcClass in
                                    Button(action: {
                                        authViewModel.updateUserProfile(field: "npcClass", value: npcClass) {
                                            DispatchQueue.main.async {
                                                authViewModel.needsOnboarding = false
                                                onClassSelected()
                                            }
                                        }
                                    }) {
                                        ZStack {
                                            Image(buttonImage)
                                                .resizable()
                                                .interpolation(.none)
                                                .scaledToFit()
                                                .frame(height: 50)
                                            
                                            Text(npcClass)
                                                .foregroundColor(.white)
                                               
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
        }
    }
