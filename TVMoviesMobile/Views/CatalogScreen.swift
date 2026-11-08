import SwiftUI

struct CatalogScreen: View {
    @EnvironmentObject private var store: CatalogStore
    @AppStorage("tvmovies_compact") private var compact = false
    let kind: CatalogKind
    let platform: String
    let search: String
    let open: (CatalogItem) -> Void

    private var entries: [CatalogItem] { store.items(for: kind, platform: platform, query: search) }

    private var highlighted: CatalogItem? { entries.first(where: \.featured) ?? entries.first }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if kind != .channels && search.isEmpty, let hero = highlighted {
                    FeaturedHero(item: hero, open: open)
                }
                categoryHeader
                if kind == .channels {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Canales").fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundStyle(.secondary)
                    }
                    .padding(15)
                    .background(TVStyle.secondary, in: RoundedRectangle(cornerRadius: 17))
                }

                if store.isLoading {
                    ProgressView("Cargando catálogo...")
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else if let error = store.errorMessage {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Problema de conexión", systemImage: "wifi.exclamationmark")
                            .font(.headline)
                        Text(error).font(.subheadline).foregroundStyle(TVStyle.muted)
                        Button("Reintentar") { store.reconnect() }
                            .buttonStyle(.borderedProminent).tint(TVStyle.red)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TVStyle.secondary, in: RoundedRectangle(cornerRadius: 18))
                } else if entries.isEmpty {
                    ContentUnavailableView("Sin contenido", systemImage: "film.stack", description: Text("No hay elementos disponibles en esta plataforma o búsqueda."))
                        .frame(minHeight: 160)
                } else {
                    if kind != .channels {
                        Text(search.isEmpty ? "Todo el catálogo" : "Resultados")
                            .font(.system(size: 23, weight: .bold))
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: compact ? 7 : 13), GridItem(.flexible(), spacing: compact ? 7 : 13)], spacing: compact ? 8 : 16) {
                        ForEach(entries) { entry in
                            Button { open(entry) } label: {
                                CatalogTile(item: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    private var categoryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATÁLOGO · \(kind.title.uppercased())")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(TVStyle.red)
                .tracking(1.4)
            Text(kind.title)
                .font(.system(size: 29, weight: .bold))
            Text(kind == .channels ? "Las mejores transmisiones y contenido multimedia." : "Explorá el catálogo de \(kind.title.lowercased()) en \(platform).")
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [TVStyle.red.opacity(0.33), Color(red: 0.09, green: 0.12, blue: 0.18), TVStyle.red.opacity(0.13)], startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(TVStyle.red.opacity(0.26), lineWidth: 1))
        }
    }
}

struct FeaturedHero: View {
    let item: CatalogItem
    let open: (CatalogItem) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                NetworkPoster(urlString: item.backdrop)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            LinearGradient(colors: [.black.opacity(0.22), .black.opacity(0.6), .black.opacity(0.96)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 9) {
                Text("DESTACADA")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(TVStyle.red, in: Capsule())
                Text(item.title)
                    .font(.system(size: 27, weight: .heavy))
                    .lineLimit(2)
                Text([item.year, item.category, item.platform].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 12.5))
                        .lineLimit(2)
                }
                Button { open(item) } label: {
                    Label("Ver ahora", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 15).padding(.vertical, 10)
                        .background(TVStyle.red, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(17)
        }
        .frame(height: 252)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct CatalogTile: View {
    let item: CatalogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                NetworkPoster(urlString: item.poster)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(item.kind == .channels ? 1.0 : 0.76, contentMode: .fit)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(item.kind == .channels ? "CANALES" : item.platform.uppercased())
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(TVStyle.muted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}
