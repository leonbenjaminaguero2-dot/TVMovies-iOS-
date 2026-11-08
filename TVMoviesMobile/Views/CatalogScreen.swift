import SwiftUI

/// Misma pantalla 'app' del HTML, sin banners inventados ni recomendaciones previas a Play.
struct CatalogScreen: View {
    @EnvironmentObject private var store: CatalogStore
    @AppStorage("tvmovies_compact") private var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("tvmovies_accent") private var accentHex = "#e50914"
    let kind: CatalogKind? // nil = entrarApp: contenido completo de la plataforma.
    let platform: String
    let search: String
    let selectPlatform: (String) -> Void
    let open: (CatalogItem) -> Void

    private var accent: Color { Color(tvHex: accentHex) }
    private var entries: [CatalogItem] {
        store.items.filter {
            ($0.platform.caseInsensitiveCompare(platform) == .orderedSame) &&
            (kind == nil || $0.kind == kind!) &&
            (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                banner
                platformPicker
                if store.isLoading {
                    ProgressView("Cargando contenido…")
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if let error = store.errorMessage {
                    VStack(spacing: 8) {
                        Text("No se pudo cargar el catálogo").font(.headline)
                        Text(error).font(.footnote).foregroundStyle(.secondary)
                        Button("Reintentar") { store.reconnect() }
                            .buttonStyle(.borderedProminent).tint(accent)
                    }
                    .frame(maxWidth: .infinity).padding(23)
                } else if entries.isEmpty {
                    Text("No hay contenido disponible todavía.")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.58))
                        .frame(maxWidth: .infinity).padding(.vertical, 28)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: compact ? 8 : 12), count: compact ? 3 : 2), spacing: compact ? 8 : 12) {
                        ForEach(entries) { item in
                            Button { open(item) } label: { tile(item) }
                                .buttonStyle(TVPressStyle())
                        }
                    }
                }
            }
            .frame(maxWidth: 480)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .animation(reduceMotion ? nil : TVMotion.selection, value: platform)
        .animation(reduceMotion ? nil : TVMotion.selection, value: compact)
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("CATÁLOGO · \(platform.uppercased())")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.5).foregroundStyle(accent)
            Text(platform).font(.system(size: 19, weight: .heavy))
            Text("Las mejores transmisiones y contenido multimedia.")
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background {
            LinearGradient(colors: [accent.opacity(0.27), Color(red: 0.075, green: 0.086, blue: 0.12).opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
                .background(.white.opacity(0.045))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
    }

    // El HTML mostraba un select debajo del banner. Se conserva aquí además del botón de nueve puntos.
    private var platformPicker: some View {
        Menu {
            ForEach(["Canales", "Netflix", "Disney+", "Prime Video"], id: \.self) { option in
                Button {
                    selectPlatform(option)
                } label: {
                    if option == platform { Label(option, systemImage: "checkmark") }
                    else { Text(option) }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up").font(.system(size: 12))
                Text(platform).font(.system(size: 12, weight: .bold))
                Spacer()
                Image(systemName: "chevron.down").font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(platformColor.opacity(0.68), in: RoundedRectangle(cornerRadius: 11))
            .foregroundStyle(.white)
        }
        .accessibilityLabel("Cambiar plataforma desde el catálogo")
    }

    private var platformColor: Color {
        switch platform {
        case "Netflix": return Color(red: 0.9, green: 0.035, blue: 0.08)
        case "Disney+": return Color(red: 0, green: 0.39, blue: 0.90)
        case "Prime Video": return Color(red: 0, green: 0.65, blue: 0.88)
        case "Canales": return Color(red: 0.025, green: 0.59, blue: 0.4)
        default: return .gray
        }
    }

    private func tile(_ item: CatalogItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                NetworkPoster(urlString: item.poster)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(1, contentMode: .fit) // El HTML usa aspect-square, no pósters 2:3.
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.system(size: compact ? 10 : 11, weight: .bold))
                    .foregroundStyle(.white).lineLimit(1)
                Text(item.platform.uppercased())
                    .font(.system(size: compact ? 8 : 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.54)).lineLimit(1)
            }
            .padding(9)
        }
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.10)))
    }
}
