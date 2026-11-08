import SwiftUI

struct AccountScreen: View {
    @Binding var username: String
    @AppStorage("tvmovies_favorites") private var storedFavorites = "[]"

    var body: some View {
        Form {
            Section("Mi cuenta") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(TVStyle.red)
                    VStack(alignment: .leading) {
                        Text("Perfil de TVMovies").font(.headline)
                        Text("Guardado en este iPhone").font(.caption).foregroundStyle(.secondary)
                    }
                }
                TextField("Nombre", text: $username)
                    .textInputAutocapitalization(.words)
                HStack {
                    Label("Mi lista", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(countFavorites)").foregroundStyle(.secondary)
                }
            }
            Section {
                Text("El catálogo se actualiza desde Firebase; el nombre y Mi lista se almacenan localmente en este dispositivo.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(TVStyle.background)
    }

    private var countFavorites: Int {
        guard let data = storedFavorites.data(using: .utf8) else { return 0 }
        return ((try? JSONDecoder().decode([String].self, from: data)) ?? []).count
    }
}

struct SettingsScreen: View {
    @EnvironmentObject private var store: CatalogStore
    let platform: String

    var body: some View {
        Form {
            Section("Información") {
                HStack {
                    Label("Firebase", systemImage: "icloud")
                    Spacer()
                    Text(store.connected ? "Conectado" : "Sin conexión")
                        .foregroundStyle(store.connected ? Color.green : Color.orange)
                }
                HStack {
                    Label("Contenido", systemImage: "square.stack.3d.up")
                    Spacer()
                    Text("\(store.items.count) elementos").foregroundStyle(.secondary)
                }
                HStack {
                    Label("Plataforma", systemImage: "square.grid.3x3")
                    Spacer()
                    Text(platform).foregroundStyle(.secondary)
                }
                Button("Actualizar conexión") { store.reconnect() }
                    .foregroundStyle(TVStyle.red)
            }
            Section("Apariencia") {
                Label("Tema oscuro de TVMovies", systemImage: "moon.stars.fill")
                Text("Barra de navegación Liquid Glass en iOS 26 o superior y material translúcido en versiones anteriores.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Versión") {
                Text("TVMovies Mobile · SwiftUI 1.0")
            }
        }
        .scrollContentBackground(.hidden)
        .background(TVStyle.background)
    }
}
