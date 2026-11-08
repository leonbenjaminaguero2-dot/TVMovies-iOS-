import SwiftUI

/// Perfil en la app: selección, creación, cambio de nombre y borrado locales.
struct AccountScreen: View {
    @Binding var username: String
    @Binding var onboarded: Bool
    @AppStorage("tvmovies_profiles_json") private var profilesJSON = "[]"
    @AppStorage("tvmovies_profile_colors") private var colorsJSON = "{}"
    @AppStorage("tvmovies_favorites") private var storedFavorites = "[]"
    @AppStorage("tvmovies_accent") private var accentHex = "#e50914"
    @State private var editingProfile = ""
    @State private var editedName = ""
    @State private var showRename = false
    @State private var deleteCandidate = ""
    @State private var confirmDelete = false
    @State private var renameError = ""

    private var profiles: [String] {
        guard let data = profilesJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
    private var colors: [String: Int] {
        guard let data = colorsJSON.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }
    private var accent: Color { Color(tvHex: accentHex) }
    private var countFavorites: Int {
        guard let data = storedFavorites.data(using: .utf8) else { return 0 }
        return ((try? JSONDecoder().decode([String].self, from: data)) ?? []).count
    }
    private let avatarPalette: [Color] = [.red, .blue, .green, .purple, .orange]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("TVMOVIES / CUENTA")
                        .font(.system(size: 10, weight: .heavy)).tracking(2)
                        .foregroundStyle(accent)
                    Text("Tu espacio")
                        .font(.system(size: 31, weight: .black)).tracking(-0.8)
                    Text("Administrá tus perfiles, como en TVMovies Mobile.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.58))
                }

                HStack(spacing: 15) {
                    avatar(name: username, size: 65)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(username).font(.system(size: 22, weight: .bold))
                        Text("PERFIL ACTUAL")
                            .font(.system(size: 10, weight: .heavy)).tracking(1.2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
                .padding(17)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.12)))

                HStack {
                    Label("Mi lista", systemImage: "bookmark.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(countFavorites) guardados")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.55))
                }
                .padding(17)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 13) {
                    Text("¿QUIÉN ESTÁ VIENDO?")
                        .font(.system(size: 11, weight: .heavy)).tracking(1.7)
                        .foregroundStyle(accent)
                    ForEach(profiles, id: \.self) { name in
                        HStack(spacing: 12) {
                            Button {
                                username = name
                                onboarded = false
                            } label: {
                                HStack(spacing: 12) {
                                    avatar(name: name, size: 45)
                                    Text(name).font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    if username == name {
                                        Text("ACTUAL")
                                            .font(.system(size: 9, weight: .heavy))
                                            .foregroundStyle(accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Menu {
                                Button("Cambiar nombre", systemImage: "pencil") {
                                    editingProfile = name
                                    editedName = name
                                    renameError = ""
                                    showRename = true
                                }
                                Button("Eliminar", systemImage: "trash", role: .destructive) {
                                    deleteCandidate = name
                                    confirmDelete = true
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(width: 38, height: 38)
                                    .background(.white.opacity(0.07), in: Circle())
                            }
                            .accessibilityLabel("Opciones para \(name)")
                        }
                        .padding(12)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                    }
                    Button {
                        username = ""
                        onboarded = false
                    } label: {
                        Label("Añadir un perfil", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity).padding(15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                }

                Button {
                    onboarded = false
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text("Cambiar plataforma")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(16)
                }
                .buttonStyle(.glass)
                .foregroundStyle(.white)

                Text("Los perfiles se guardan solamente en este iPhone.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.43))
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .alert("Cambiar nombre", isPresented: $showRename) {
            TextField("Nombre del perfil", text: $editedName)
            Button("Guardar") { renameProfile() }
            Button("Cancelar", role: .cancel) { }
        } message: { Text("Elegí el nombre para este perfil (máximo 24 caracteres).") }
        .confirmationDialog("¿Eliminar el perfil \(deleteCandidate)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Eliminar perfil", role: .destructive) { deleteProfile(deleteCandidate) }
            Button("Cancelar", role: .cancel) { }
        } message: { Text("Esto elimina el perfil de este iPhone.") }
        .alert("No se pudo cambiar el nombre", isPresented: Binding(
            get: { !renameError.isEmpty }, set: { if !$0 { renameError = "" } }
        )) { Button("Entendido") { renameError = "" } } message: { Text(renameError) }
    }

    private func avatar(name: String, size: CGFloat) -> some View {
        let index = min(max(colors[name] ?? 0, 0), avatarPalette.count - 1)
        return Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.43, weight: .black))
            .frame(width: size, height: size)
            .background(avatarPalette[index].gradient, in: Circle())
    }

    private func saveProfiles(_ names: [String]) {
        if let data = try? JSONEncoder().encode(names),
           let json = String(data: data, encoding: .utf8) { profilesJSON = json }
    }
    private func saveColors(_ map: [String: Int]) {
        if let data = try? JSONEncoder().encode(map),
           let json = String(data: data, encoding: .utf8) { colorsJSON = json }
    }
    private func renameProfile() {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && name.count <= 24 else {
            renameError = "Usá entre 1 y 24 caracteres."; return
        }
        guard !profiles.contains(where: { $0 != editingProfile && $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            renameError = "Ese nombre ya está en uso."; return
        }
        saveProfiles(profiles.map { $0 == editingProfile ? name : $0 })
        var palette = colors
        palette[name] = palette.removeValue(forKey: editingProfile) ?? 0
        saveColors(palette)
        if username == editingProfile { username = name }
    }
    private func deleteProfile(_ name: String) {
        saveProfiles(profiles.filter { $0 != name })
        var palette = colors
        palette.removeValue(forKey: name)
        saveColors(palette)
        if username == name {
            username = ""
            onboarded = false
        }
    }
}

/// Ajustes según Movil(1).html. No se expone configuración técnica de Firebase.
struct SettingsScreen: View {
    @Binding var username: String
    @Binding var onboarded: Bool
    @AppStorage("tvmovies_accent") private var accent = "#e50914"
    @AppStorage("tvmovies_compact") private var compact = false
    @AppStorage("tvmovies_language") private var language = "es"

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TVMOVIES / AJUSTES").font(.system(size: 10, weight: .heavy))
                        .tracking(2).foregroundStyle(Color(tvHex: accent))
                    Text("Personalizá tu experiencia")
                        .font(.system(size: 24, weight: .black))
                }
                .listRowBackground(Color.clear)
            }
            Section("Apariencia y Tema") {
                Picker("Color de énfasis", selection: $accent) {
                    Text("Rojo Clásico").tag("#e50914")
                    Text("Azul Cyan").tag("#00a8e1")
                    Text("Verde Esmeralda").tag("#10b981")
                    Text("Violeta Pro").tag("#8b5cf6")
                }
                Toggle("Diseño compacto", isOn: $compact)
            }
            Section("Preferencias Generales") {
                Picker("Idioma de la interfaz", selection: $language) {
                    Text("Español").tag("es")
                    Text("English").tag("en")
                }
            }
            Section("Cuentas locales") {
                Button("Administrar perfiles") {
                    username = ""
                    onboarded = false
                }
                Button("Cambiar de plataforma") { onboarded = false }
            }
            Section {
                Button("Restaurar configuración original") {
                    accent = "#e50914"
                    compact = false
                    language = "es"
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TVStyle.background)
    }
}
