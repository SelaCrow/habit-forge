import SwiftUI

struct FlavorSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var hasSelectedFlavor = false
    @State private var isUpdating = false

    // Map flavor names to image asset names
    let flavorImages: [String: String] = [
        "Fantasy": "fantasy_button",
        "Sci-Fi": "sci_fi_button"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Image("choose_a_flavor")
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 80)

            ForEach(flavorImages.keys.sorted(), id: \.self) { flavor in
                Button(action: {
                    isUpdating = true
                    authViewModel.updateUserProfile(field: "flavorText", value: flavor.lowercased()) {
                        DispatchQueue.main.async {
                            authViewModel.characterClass = nil
                            authViewModel.needsOnboarding = true
                            withAnimation {
                                isUpdating = false
                                hasSelectedFlavor = true
                            }
                        }
                    }
                }) {
                    Image(flavorImages[flavor]!)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 90)
                        .opacity(isUpdating ? 0.5 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUpdating)
            }

            if isUpdating {
                ProgressView("Updating flavor...")
            }

            if hasSelectedFlavor {
                Text("Flavor updated! Proceed to select your class.")
                    .font(.headline)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding()
    }
}

