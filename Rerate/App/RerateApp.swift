import SwiftUI

@main
struct RerateApp: App {
    /// `-reset` starts with an empty portfolio, so onboarding can be seen
    /// without deleting the seeded demonstration positions.
    @State private var store = Store(
        demo: !ProcessInfo.processInfo.arguments.contains("-reset")
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Palette.accent)
        }
    }
}
