import SwiftUI
import UIKit

/// One small set of springs, used everywhere. Consistency of motion is most of
/// what makes an app feel like a single object rather than a pile of screens.
enum Motion {
    /// Default for taps, state flips, pill changes.
    static let snappy = Animation.spring(response: 0.34, dampingFraction: 0.86)
    /// Larger surfaces: sheets, expanding sections, hero content.
    static let gentle = Animation.spring(response: 0.48, dampingFraction: 0.9)
    /// Immediate feedback that should never feel loose.
    static let crisp = Animation.spring(response: 0.24, dampingFraction: 0.95)
    /// Continuous values driven by a finger — no bounce, tracks the touch.
    static let tracking = Animation.interactiveSpring(response: 0.22, dampingFraction: 1.0)
    /// Drawing a path or revealing a figure for the first time.
    static let draw = Animation.easeOut(duration: 0.75)

    /// Staggered reveal for lists of content.
    static func cascade(_ index: Int, base: Double = 0.04, response: Double = 0.5) -> Animation {
        .spring(response: response, dampingFraction: 0.9).delay(Double(index) * base)
    }
}

enum Haptic {
    private static let selection = UISelectionFeedbackGenerator()

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    static func firm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    static func detent() {
        selection.selectionChanged()
    }

    static func settled() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func prepare() {
        selection.prepare()
    }
}

/// Presses scale the whole surface very slightly and dim it. No shadow tricks.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.978
    var haptic: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(Motion.crisp, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && haptic { Haptic.tap() }
            }
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
    static func pressable(scale: CGFloat) -> PressableStyle { PressableStyle(scale: scale) }
    static func pressable(scale: CGFloat, haptic: Bool) -> PressableStyle {
        PressableStyle(scale: scale, haptic: haptic)
    }
}
