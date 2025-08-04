import SwiftUI

struct SplashScreenView: View {
    @State private var currentFrame = 0
    @State private var opacity: Double = 1.0

    let totalFrames = 11
    let frameDuration = 0.12

    let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("frame\(currentFrame)")
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // 👈 fixed size
                .opacity(opacity)
                .ignoresSafeArea()
        }
        .onReceive(timer) { _ in
            if currentFrame < totalFrames - 1 {
                currentFrame += 1
            } else {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
            }
        }
    }
}
