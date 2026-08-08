import SwiftUI

struct RootView: View {
    @Environment(Store.self) private var store

    var body: some View {
        Group {
            if store.hasOnboarded {
                PortfolioView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(Motion.gentle, value: store.hasOnboarded)
        .background(Palette.canvas.ignoresSafeArea())
    }
}
