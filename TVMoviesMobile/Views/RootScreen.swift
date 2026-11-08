import SwiftUI

enum TVTab: Int, CaseIterable, Hashable {
    case movies, series, channels, account, settings

    var label: String {
        switch self {
        case .movies: return "Películas"
        case .series: return "Series"
        case .channels: return "Canales"
        case .account: return "Cuenta"
        case .settings: return "Ajustes"
        }
    }

    var icon: String {
        switch self {
        case .movies: return "film"
        case .series: return "tv"
        case .channels: return "dot.radiowaves.left.and.right"
        case .account: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}

/// TVMovies Mobile: no es una web ni un efecto CSS.
/// La TabView del sistema usa la barra flotante Liquid Glass REAL de iOS 26+.
struct RootScreen: View {
    @EnvironmentObject private var store: CatalogStore
    @AppStorage("tvmovies_user") private var username = ""
    @AppStorage("tvmovies_profiles_json") private var profilesJSON = "[]"
    @AppStorage("tvmovies_onboarded") private var onboarded = false
    @State private var sessionActive = false
    @State private var selected: TVTab = .movies
    @State private var search = ""
    @AppStorage("tvmovies_platform") private var platform = "Netflix"
    @AppStorage("tvmovies_accent") private var accentHex = "#e50914"
    @State private var openedItem: CatalogItem?
    @State private var showPlatformPicker = false

    var body: some View {
        Group {
        if !sessionActive || !onboarded || username.isEmpty {
            TVMoviesOnboarding(username: $username, profilesJSON: $profilesJSON, onboarded: $onboarded, sessionActive: $sessionActive, platform: $platform)
        } else {
        TabView(selection: $selected) {
            tab(.movies) {
                catalogPage(.movies)
            }
            tab(.series) {
                catalogPage(.series)
            }
            tab(.channels) {
                catalogPage(.channels)
            }
            tab(.account) {
                screenShell {
                    AccountScreen(username: $username, onboarded: $onboarded)
                }
            }
            tab(.settings) {
                screenShell {
                    SettingsScreen(username: $username, onboarded: $onboarded)
                }
            }
        }
        .tint(Color(tvHex: accentHex))
        // Sin barras dibujadas a mano: SwiftUI proporciona Liquid Glass
        // con respuesta nativa a la selección y transiciones del sistema.
        .preferredColorScheme(.dark)
        .sheet(item: $openedItem) { item in
            DetailScreen(item: item)
        }
        .confirmationDialog("Cambiar plataforma", isPresented: $showPlatformPicker, titleVisibility: .visible) {
            ForEach(["Canales", "Netflix", "Disney+", "Prime Video"], id: \.self) { option in
                Button(option + (option == platform ? " ✓" : "")) {
                    platform = option
                    if option == "Canales" { selected = .channels } else if selected == .channels { selected = .movies }
                }
            }
        } message: {
            Text("Elegí otra plataforma para continuar viendo contenido.")
        }
        }
        }
        .onChange(of: sessionActive) { _, active in
            if active { selected = platform == "Canales" ? .channels : .movies }
        }
    }

    private func tab<Content: View>(_ tab: TVTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .tabItem { Label(tab.label, systemImage: tab.icon) }
            .tag(tab)
    }

    private func catalogPage(_ kind: CatalogKind) -> some View {
        screenShell {
            CatalogScreen(kind: kind, platform: kind == .channels ? "Canales" : platform, search: search) { item in
                openedItem = item
            }
        }
    }

    private func screenShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(.white.opacity(0.09))
                .frame(height: 1)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            TVStyle.background.ignoresSafeArea()
            RadialGradient(
                colors: [TVStyle.red.opacity(0.19), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 580
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                Text("TV")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(TVStyle.red, in: RoundedRectangle(cornerRadius: 10))
                Text("TVMovies")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 1)

            if selected == .movies || selected == .series || selected == .channels {
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                    TextField("Buscar…", text: $search)
                        .font(.system(size: 12))
                        .tint(TVStyle.red)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 10)
                .frame(width: 96, height: 38)
                .glassEffect(.regular, in: Capsule())
                .accessibilityLabel("Buscar contenido")
            }

            Button { showPlatformPicker = true } label: {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 17))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Cambiar plataforma")

            Button { selected = .account } label: {
                HStack(spacing: 5) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 15))
                    Text(String(username.prefix(7)))
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .frame(height: 36)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Abrir cuenta")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.black.opacity(0.67))
    }
}
