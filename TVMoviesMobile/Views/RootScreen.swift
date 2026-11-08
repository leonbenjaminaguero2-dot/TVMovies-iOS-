import SwiftUI

enum TVTab: Int, CaseIterable, Hashable {
    case movies, series, channels, settings, account

    var label: String {
        switch self {
        case .movies: return "Películas"
        case .series: return "Series"
        case .channels: return "Canales"
        case .settings: return "Ajustes"
        case .account: return "Cuenta"
        }
    }
    var icon: String {
        switch self {
        case .movies: return "film"
        case .series: return "tv"
        case .channels: return "dot.radiowaves.left.and.right"
        case .settings: return "gearshape"
        case .account: return "person.crop.circle"
        }
    }
}

/// Implementación SwiftUI nativa del HTML Movil(1).html.
/// Solo la navegación y los controles interactivos usan el Liquid Glass real de iOS.
struct RootScreen: View {
    @EnvironmentObject private var store: CatalogStore
    @AppStorage("tvmovies_user") private var username = ""
    @AppStorage("tvmovies_profiles_json") private var profilesJSON = "[]"
    @AppStorage("tvmovies_onboarded") private var onboarded = false
    @AppStorage("tvmovies_platform") private var platform = "Netflix"
    @AppStorage("tvmovies_accent") private var accentHex = "#e50914"
    @State private var sessionActive = false // HTML pide perfil al iniciar, también si existe uno.
    @State private var selected: TVTab = .movies
    @State private var showAll = true // El HTML muestra todo el contenido de la plataforma al entrar.
    @State private var search = ""
    @State private var openedItem: CatalogItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { Color(tvHex: accentHex) }
    private let platforms = ["Canales", "Netflix", "Disney+", "Prime Video"]

    var body: some View {
        Group {
            if !sessionActive || !onboarded || username.isEmpty {
                TVMoviesOnboarding(username: $username, profilesJSON: $profilesJSON,
                    onboarded: $onboarded, sessionActive: $sessionActive, platform: $platform)
            } else {
                TabView(selection: Binding(get: { selected }, set: { tab in
                    withAnimation(reduceMotion ? nil : TVMotion.selection) { selected = tab }
                    showAll = false
                    if tab == .channels { platform = "Canales" }
                })) {
                    catalogTab(.movies)
                    catalogTab(.series)
                    catalogTab(.channels)
                    tab(.settings) {
                        pageShell { SettingsScreen(username: $username, onboarded: $onboarded) }
                    }
                    tab(.account) {
                        pageShell { AccountScreen(username: $username, onboarded: $onboarded) }
                    }
                }
                .tint(accent)
                .sheet(item: $openedItem) { item in DetailScreen(item: item) }
            }
        }
        .animation(reduceMotion ? nil : TVMotion.page, value: sessionActive)
        .preferredColorScheme(.dark)
        .onChange(of: sessionActive) { _, active in
            if active {
                selected = .movies
                showAll = true
                search = ""
            }
        }
    }

    private func catalogTab(_ kind: TVTab) -> some View {
        tab(kind) {
            pageShell {
                CatalogScreen(kind: showAll && selected == kind ? nil : catalogKind(kind),
                              platform: platform, search: search, selectPlatform: { option in
                    platform = option
                    selected = .movies
                    showAll = true
                    search = ""
                }) { openedItem = $0 }
            }
        }
    }

    private func catalogKind(_ tab: TVTab) -> CatalogKind? {
        switch tab {
        case .movies: return .movies
        case .series: return .series
        case .channels: return .channels
        default: return nil
        }
    }

    private func tab<Content: View>(_ tab: TVTab, @ViewBuilder content: () -> Content) -> some View {
        content().tabItem { Label(tab.label, systemImage: tab.icon) }.tag(tab)
    }

    private func pageShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(.white.opacity(0.09)).frame(height: 1)
            content().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            ZStack {
                Color(red: 5/255, green: 6/255, blue: 9/255)
                RadialGradient(colors: [accent.opacity(0.12), .clear], center: .topTrailing, startRadius: 0, endRadius: 350)
            }.ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            HStack(spacing: 8) {
                Text("TV")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(accent, in: RoundedRectangle(cornerRadius: 8))
                Text("TVMovies")
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.45)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            if selected == .movies || selected == .series || selected == .channels {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 11))
                    TextField("Buscar...", text: $search)
                        .font(.system(size: 11))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .tint(accent)
                }
                .padding(.horizontal, 8)
                .frame(width: 92, height: 32)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 11))
                .accessibilityLabel("Buscar contenido")
            }
            Menu {
                ForEach(platforms, id: \.self) { option in
                    Button {
                        platform = option
                        selected = .movies
                        showAll = true
                        search = ""
                    } label: {
                        if option == platform { Label(option, systemImage: "checkmark") }
                        else { Text(option) }
                    }
                }
            } label: {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 15))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Cambiar plataforma")
            Button {
                selected = .account
                showAll = false
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 15))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Abrir cuentas")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.black.opacity(0.56))
    }
}
