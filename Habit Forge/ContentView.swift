import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    @State private var showSignUpForm = false
    @State private var showLoginForm = false
    @State private var showMainContent = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Background
            Image("main_background")
                .resizable()
                .interpolation(.none)
                .ignoresSafeArea()
            if showSplash || authViewModel.isLoading {
                SplashScreenView()
                    .zIndex(10)
            }

            // Initial app splash screen
//            if showSplash {
//                SplashScreenView()
//                    .zIndex(10)
//            }

            // Main content
            currentMainView()
                .padding()

            // Error message banner
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .transition(.move(edge: .top))
                    .zIndex(20)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !authViewModel.isLoading {
                    withAnimation {
                        showSplash = false
                        showMainContent = true
                    }
                }
            }
        }
        .onChange(of: authViewModel.userSession) { _, newValue in
            if newValue == nil {
                showLoginForm = false
                showSignUpForm = false
            } else {
                showSplash = true
            }
        }
        .onChange(of: authViewModel.finishedLoadingProfile) { _, finished in
                    if finished && authViewModel.isLoggedIn {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                showSplash = false
                                showMainContent = true
                            }
                }
            }
        }
        .onChange(of: authViewModel.isLoading) { _, loading in
            if loading {
                showSplash = true
            }
        }
    }

    // MARK: - View Builder for current main view state
    @ViewBuilder
    private func currentMainView() -> some View {
        if !showMainContent || authViewModel.isLoading {
            EmptyView()
        } else if authViewModel.userSession == nil {
            loginSignupForm()
        } else if authViewModel.isLoggedIn && authViewModel.finishedLoadingProfile {
            if authViewModel.needsOnboarding {
                if authViewModel.flavorText == nil {
                    ZStack {
                        Image("long-background")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFill()
                            .ignoresSafeArea()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

                        FlavorSelectionView()
                            .environmentObject(authViewModel)
                    }
                } else if authViewModel.characterClass == nil {
                    ZStack {
                
                            Image("long-background")
                                .resizable()
                                .interpolation(.none)
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                .ignoresSafeArea()
                        
                        ClassSelectionView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    QuestBoardView(authViewModel: authViewModel)
                }
            } else {
                QuestBoardView(authViewModel: authViewModel)
            }
        }
    }

    // MARK: - Login / Signup form
    private func loginSignupForm() -> some View {
        ZStack {
            VStack {
                Spacer(minLength: 500)

                if !showLoginForm && !showSignUpForm {
                    VStack(spacing: -20) {
                        Button(action: {
                            withAnimation {
                                showSignUpForm = true
                                showLoginForm = false
                                authViewModel.errorMessage = nil
                            }
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image("Sign_up")
                                    .resizable()
                                    .interpolation(.none)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 300, height: 90)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            withAnimation {
                                showLoginForm = true
                                showSignUpForm = false
                                authViewModel.errorMessage = nil
                            }
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image("log_in")
                                    .resizable()
                                    .interpolation(.none)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 300, height: 90)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            authViewModel.signInAnonymously()
                        }) {
                            Image("start_as_guest")
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 90)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 80)
                }

                Spacer()
            }

            if showLoginForm {
                LoginView(onCancel: {
                    withAnimation {
                        showLoginForm = false
                        authViewModel.errorMessage = nil
                    }
                })
                .environmentObject(authViewModel)
                .zIndex(5)
            }

            if showSignUpForm {
                SignUpView(
                    onCancel: {
                        withAnimation {
                            showSignUpForm = false
                            authViewModel.errorMessage = nil
                        }
                    }
                )
                .environmentObject(authViewModel)
                .zIndex(5)
            }
        }
    }
}
