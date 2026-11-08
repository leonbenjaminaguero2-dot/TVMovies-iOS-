import SwiftUI

private enum WelcomeStep: Equatable {
    case profiles, create, platforms
}

/// El mismo recorrido del HTML: crear/elegir perfil -> plataforma -> catálogo.
/// Interfaz nativa, sin WebView. Los perfiles son locales, no credenciales de streaming.
struct TVMoviesOnboarding: View {
    @Binding var username: String
    @Binding var profilesJSON: String
    @Binding var onboarded: Bool
    @Binding var sessionActive: Bool
    @Binding var platform: String

    @AppStorage("tvmovies_profile_colors") private var colorsJSON = "{}"
    @AppStorage("tvmovies_accent") private var accentHex = "#e50914"
    @State private var step: WelcomeStep = .profiles
    @State private var newName = ""
    @State private var selectedAvatar = 0
    @State private var errorMessage = ""
    @FocusState private var nameFocused: Bool

    private let avatarPalette: [Color] = [
        Color(red: 0.90, green: 0.05, blue: 0.10),
        Color(red: 0.05, green: 0.55, blue: 0.90),
        Color(red: 0.12, green: 0.68, blue: 0.43),
        Color(red: 0.55, green: 0.30, blue: 0.91),
        Color(red: 0.96, green: 0.53, blue: 0.12)
    ]

    private var profiles: [String] {
        guard let data = profilesJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private var savedAvatarColors: [String: Int] {
        guard let data = colorsJSON.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    private var accent: Color { Color(tvHex: accentHex) }

    var body: some View {
        ZStack {
            Color(red: 0.019, green: 0.024, blue: 0.035).ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.23), .clear], center: .topLeading, startRadius: 15, endRadius: 500)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    brand
                    switch step {
                    case .profiles: profilePage
                    case .create: createPage
                    case .platforms: platformPage
                    }
                    Text("TVMOVIES  ·  MOBILE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.3)
                        .foregroundStyle(.white.opacity(0.28))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 23)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(.white)
        .tint(accent)
        .preferredColorScheme(.dark)
        .onAppear {
            if profiles.isEmpty { step = .create }
            else if !username.isEmpty && !onboarded { step = .platforms }
            else { step = .profiles }
        }
    }

    private var brand: some View {
        HStack(spacing: 11) {
            Text("TV")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .frame(width: 43, height: 43)
                .background(accent, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 0) {
                Text("TVMovies").font(.system(size: 20, weight: .heavy)).tracking(-0.6)
                Text("TU ENTRETENIMIENTO").font(.system(size: 8, weight: .bold)).tracking(1.9)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            if step == .platforms || (step == .create && !profiles.isEmpty) {
                Button {
                    nameFocused = false
                    step = .profiles
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 39, height: 39)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Volver a perfiles")
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 48)
    }

    private func eyebrow(_ value: String) -> some View {
        Text(value).font(.system(size: 10, weight: .heavy)).tracking(2)
            .foregroundStyle(accent)
            .padding(.bottom, 11)
    }

    private var profilePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("TU ESPACIO")
            Text("¿Quién está viendo?")
                .font(.system(size: 32, weight: .black)).tracking(-1)
            Text("Seleccioná tu perfil para continuar.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8).padding(.bottom, 29)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 13) {
                ForEach(profiles, id: \.self) { name in
                    Button {
                        username = name
                        step = .platforms
                    } label: {
                        VStack(spacing: 13) {
                            avatar(name: name, index: savedAvatarColors[name] ?? 0, diameter: 70)
                            Text(name).font(.system(size: 15, weight: .bold))
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text("ENTRAR  ›")
                                .font(.system(size: 10, weight: .heavy)).tracking(1.5)
                                .foregroundStyle(.white.opacity(0.43))
                        }
                        .frame(maxWidth: .infinity).frame(height: 173)
                        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Entrar con el perfil \(name)")
                }

                Button {
                    newName = ""
                    errorMessage = ""
                    selectedAvatar = 0
                    step = .create
                } label: {
                    VStack(spacing: 13) {
                        Image(systemName: "plus")
                            .font(.system(size: 29, weight: .light))
                            .frame(width: 70, height: 70)
                            .background(.white.opacity(0.065), in: Circle())
                        Text("Añadir perfil").font(.system(size: 15, weight: .bold))
                        Text("NUEVA CUENTA")
                            .font(.system(size: 10, weight: .heavy)).tracking(1.5)
                            .foregroundStyle(.white.opacity(0.43))
                    }
                    .frame(maxWidth: .infinity).frame(height: 173)
                    .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 19))
                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.19), style: StrokeStyle(lineWidth: 1, dash: [6, 5])))
                }
                .buttonStyle(.plain)
            }
            Text("Los perfiles se guardan únicamente en este iPhone.")
                .font(.footnote).foregroundStyle(.white.opacity(0.42))
                .padding(.top, 23)
        }
    }

    private var createPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("PASO 01  /  02")
            Text("Creá tu perfil.")
                .font(.system(size: 34, weight: .black)).tracking(-1.2)
            Text("Elegí un nombre y tu color. Después vas a elegir qué plataforma querés ver.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            HStack {
                Spacer()
                avatar(name: newName.isEmpty ? "T" : newName, index: selectedAvatar, diameter: 104)
                    .padding(.vertical, 29)
                Spacer()
            }

            Text("ELEGÍ TU COLOR")
                .font(.system(size: 11, weight: .bold)).tracking(1.5)
                .foregroundStyle(.white.opacity(0.66))
                .padding(.bottom, 13)
            HStack(spacing: 13) {
                ForEach(avatarPalette.indices, id: \.self) { index in
                    Button { selectedAvatar = index } label: {
                        Circle().fill(avatarPalette[index])
                            .frame(width: 38, height: 38)
                            .overlay {
                                if selectedAvatar == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(Circle().stroke(.white.opacity(selectedAvatar == index ? 0.9 : 0), lineWidth: 2).padding(-4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color de perfil \(index + 1)")
                }
            }
            .padding(.bottom, 29)

            Text("NOMBRE DEL PERFIL")
                .font(.system(size: 11, weight: .bold)).tracking(1.5)
                .foregroundStyle(.white.opacity(0.66))
                .padding(.bottom, 10)
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle").foregroundStyle(.white.opacity(0.6))
                TextField("Ej.: Benja", text: $newName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .onSubmit(createProfile)
                    .onChange(of: newName) { _, _ in errorMessage = "" }
            }
            .font(.system(size: 16))
            .padding(17)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.15)))

            if !errorMessage.isEmpty {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    .padding(.top, 9)
            }
            Button(action: createProfile) {
                HStack {
                    Spacer()
                    Text("Crear perfil").font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .frame(height: 53)
                .background(accent, in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
            .padding(.top, 22)

            if !profiles.isEmpty {
                Button("Ya tengo perfil") { step = .profiles }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.73))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 19)
            }
        }
    }

    private var platformPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("PASO 02  /  02")
            HStack(spacing: 10) {
                avatar(name: username, index: savedAvatarColors[username] ?? 0, diameter: 39)
                Text("Hola, \(username)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))
            }
            .padding(.bottom, 18)
            Text("¿Qué plataforma\nquerés ver?")
                .font(.system(size: 33, weight: .black)).tracking(-1)
                .fixedSize(horizontal: false, vertical: true)
            Text("Elegí una opción para entrar al catálogo. Podés cambiarla después.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.60))
                .padding(.top, 10).padding(.bottom, 28)

            platformCard("Canales de TV", subtitle: "EN VIVO", symbol: "dot.radiowaves.left.and.right", value: "Canales", color: Color(red: 0.05, green: 0.58, blue: 0.39), height: 94)
                .padding(.bottom, 13)
            HStack(spacing: 13) {
                platformCard("NETFLIX", subtitle: "PELÍCULAS Y SERIES", symbol: "play.rectangle.fill", value: "Netflix", color: Color(red: 0.83, green: 0.04, blue: 0.10), height: 138)
                platformCard("Disney+", subtitle: "PELÍCULAS Y SERIES", symbol: "sparkles.tv", value: "Disney+", color: Color(red: 0.04, green: 0.35, blue: 0.79), height: 138)
            }
            .padding(.bottom, 13)
            platformCard("prime video", subtitle: "PELÍCULAS Y SERIES", symbol: "play.tv", value: "Prime Video", color: Color(red: 0.01, green: 0.48, blue: 0.72), height: 88)

            Button {
                username = ""
                step = .profiles
            } label: {
                Label("Cambiar de perfil", systemImage: "person.2")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .foregroundStyle(.white.opacity(0.64))
            .buttonStyle(.plain)
        }
    }

    private func platformCard(_ label: String, subtitle: String, symbol: String, value: String, color: Color, height: CGFloat) -> some View {
        Button {
            platform = value
            onboarded = true
            sessionActive = true
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [color, color.opacity(0.78), color.opacity(0.50)], startPoint: .leading, endPoint: .trailing))
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(subtitle, systemImage: symbol)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.5)
                            .lineLimit(1)
                            .foregroundStyle(.white.opacity(0.72))
                        if value == "Netflix" {
                            Image("NetflixBrand").resizable().scaledToFit()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 30)
                        } else if value == "Disney+" {
                            Image("DisneyBrand").resizable().scaledToFit()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 38)
                        } else if value == "Prime Video" {
                            Image("PrimeBrand").resizable().scaledToFit()
                                .frame(maxWidth: 175, alignment: .leading)
                                .frame(height: 32)
                        } else {
                            Text(label)
                                .font(.system(size: 21, weight: .black))
                                .tracking(-0.5).lineLimit(2).minimumScaleFactor(0.75)
                        }
                    }
                    Spacer(minLength: 2)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.17), in: Circle())
                }
                .padding(17)
            }
            .frame(height: height)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver \(value)")
    }

    private func avatar(name: String, index: Int, diameter: CGFloat) -> some View {
        let safeIndex = min(max(index, 0), avatarPalette.count - 1)
        return Text(String(name.prefix(1)).uppercased())
            .font(.system(size: diameter * 0.44, weight: .black, design: .rounded))
            .frame(width: diameter, height: diameter)
            .background(LinearGradient(colors: [avatarPalette[safeIndex], avatarPalette[safeIndex].opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 2))
    }

    private func createProfile() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { errorMessage = "Escribí un nombre para continuar."; return }
        guard name.count <= 24 else { errorMessage = "El nombre debe tener como máximo 24 caracteres."; return }
        guard !profiles.contains(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            errorMessage = "Ese perfil ya existe. Elegí otro nombre."
            return
        }
        var updated = profiles
        updated.append(name)
        guard let data = try? JSONEncoder().encode(updated),
              let json = String(data: data, encoding: .utf8) else { return }
        profilesJSON = json
        var colors = savedAvatarColors
        colors[name] = selectedAvatar
        if let saved = try? JSONEncoder().encode(colors),
           let value = String(data: saved, encoding: .utf8) { colorsJSON = value }
        username = name
        nameFocused = false
        step = .platforms
    }
}
