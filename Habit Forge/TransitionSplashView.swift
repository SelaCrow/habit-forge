import SwiftUI

struct TransitionSplashView: View {
    @Binding var isVisible: Bool
    @State private var currentFrame = 0
    let totalFrames = 11
    let minDuration: Double = 1.5

    let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if isVisible {
                GeometryReader { geometry in
                    ZStack {
                        Color.black.ignoresSafeArea()

                        Image("frame\(currentFrame)")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .ignoresSafeArea()
                    }
                }
                .onReceive(timer) { _ in
                    currentFrame = (currentFrame + 1) % totalFrames
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + minDuration) {
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: isVisible)
    }
}
