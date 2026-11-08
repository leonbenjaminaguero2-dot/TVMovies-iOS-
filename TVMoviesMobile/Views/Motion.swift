import SwiftUI

/// Animaciones discretas que respetan Reducir movimiento de Accesibilidad.
enum TVMotion {
    static let page = Animation.spring(response: 0.43, dampingFraction: 0.86)
    static let selection = Animation.spring(response: 0.30, dampingFraction: 0.78)
}

struct TVPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.965 : 1))
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : TVMotion.selection, value: configuration.isPressed)
    }
}
