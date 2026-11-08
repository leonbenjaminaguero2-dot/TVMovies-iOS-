import SwiftUI

enum TVStyle {
    static let red = Color(red: 0.92, green: 0.035, blue: 0.09)
    static let background = Color(red: 0.042, green: 0.025, blue: 0.035)
    static let secondary = Color(red: 0.13, green: 0.105, blue: 0.13)
    static let muted = Color(red: 0.66, green: 0.65, blue: 0.70)
}

// Liquid Glass auténtico: API de SwiftUI incorporada a iOS 26.
// Se reserva para controles y navegación, no para todos los pósters.
struct GlassSurface: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    func tvGlass(radius: CGFloat = 24) -> some View {
        modifier(GlassSurface(radius: radius))
    }
}

struct NetworkPoster: View {
    let urlString: String
    var mode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: mode)
            case .empty:
                Rectangle().fill(Color.white.opacity(0.06))
                    .overlay(ProgressView().tint(TVStyle.red))
            case .failure:
                Rectangle().fill(Color.white.opacity(0.06))
                    .overlay(Image(systemName: "film").font(.largeTitle).foregroundStyle(.gray))
            @unknown default:
                Color.black
            }
        }
        .clipped()
    }
}

extension Color {
    init(tvHex: String) {
        let raw = tvHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard raw.count == 6, let value = UInt64(raw, radix: 16) else {
            self = TVStyle.red
            return
        }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
