import SwiftUI

/// Flujo del HTML original: perfiles locales -> elegir plataforma -> catálogo.
struct TVMoviesOnboarding: View {
    @Binding var username: String
    @Binding var profilesJSON: String
    @Binding var onboarded: Bool
    @Binding var platform: String
    @State private var newName = ""
    @State private var creating = false
    @State private var choosingPlatform = false

    private var profiles: [String] {
        guard let data = profilesJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text("TVMovies")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.top, 50)
                    if choosingPlatform {
                        Text("¿Qué plataforma quieres ver?")
                            .font(.title2.bold())
                        platformButton("Canales de TV", value: "Canales", color: .green)
                        HStack(spacing: 12) {
                            platformButton("Netflix", value: "Netflix", color: .red)
                            platformButton("Disney+", value: "Disney+", color: .blue)
                        }
                        platformButton("Prime Video", value: "Prime Video", color: .cyan)
                        Button("Volver a perfiles") { choosingPlatform = false }
                            .foregroundStyle(.secondary)
                    } else if creating || profiles.isEmpty {
                        Text("Crea una cuenta").font(.title2.bold())
                        Text("Ingresa el nombre de usuario").foregroundStyle(.secondary)
                        TextField("Nombre", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 20)
                        Button("Crear") {
                            let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            var all = profiles
                            if !all.contains(name) { all.append(name) }
                            if let data = try? JSONEncoder().encode(all), let value = String(data: data, encoding: .utf8) {
                                profilesJSON = value
                            }
                            username = name
                            creating = false
                            choosingPlatform = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if !profiles.isEmpty {
                            Button("Cancelar") { creating = false }
                        }
                    } else {
                        Text("¿Quién está viendo?").font(.title2.bold())
                        Text("Selecciona o añade tu perfil").foregroundStyle(.secondary)
                        ForEach(profiles, id: \.self) { name in
                            Button {
                                username = name
                                choosingPlatform = true
                            } label: {
                                Label(name, systemImage: "person.crop.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                            }
                            .buttonStyle(.glass)
                        }
                        Button("Añadir perfil") { creating = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            }
            .background(Color(red: 0.035, green: 0.04, blue: 0.06).ignoresSafeArea())
            .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
    }

    private func platformButton(_ label: String, value: String, color: Color) -> some View {
        Button {
            platform = value
            onboarded = true
        } label: {
            Text(label).font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
