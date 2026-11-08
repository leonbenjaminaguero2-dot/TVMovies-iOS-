import Foundation

enum CatalogKind: String, CaseIterable {
    case movies = "pelis"
    case series = "series"
    case channels = "canales"

    var title: String {
        switch self {
        case .movies: return "Películas"
        case .series: return "Series"
        case .channels: return "Canales"
        }
    }

    static func from(_ value: String?) -> Self? {
        switch (value ?? "").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased() {
        case "pelis", "peliculas", "pelicula", "movies": return .movies
        case "series", "serie": return .series
        case "canales", "canal", "tv": return .channels
        default: return nil
        }
    }
}

struct Episode: Identifiable {
    let number: Int
    let title: String
    let stream: String
    var id: String { "\(number)-\(title)-\(stream)" }

    init?(_ data: Any, fallbackNumber: Int) {
        guard let row = data as? [String: Any] else { return nil }
        let link = CatalogItem.string(row["link"]) ?? CatalogItem.string(row["stream"]) ?? ""
        guard !link.isEmpty else { return nil }
        number = (row["numero"] as? NSNumber)?.intValue ?? Int("\(row["numero"] ?? "")") ?? fallbackNumber
        title = CatalogItem.string(row["titulo"]) ?? "Capítulo \(number)"
        stream = link
    }
}

struct CatalogItem: Identifiable {
    let id: String
    let title: String
    let kind: CatalogKind
    let platform: String
    let poster: String
    let backdrop: String
    let stream: String
    let description: String
    let episodes: [Episode]
    let year: String
    let category: String
    let featured: Bool

    static func string(_ any: Any?) -> String? {
        guard let any = any else { return nil }
        if let text = any as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let number = any as? NSNumber { return number.stringValue }
        return nil
    }

    init?(id: String, data: [String: Any]) {
        guard let type = CatalogKind.from(Self.string(data["tipo"])) else { return nil }
        self.id = id
        self.kind = type
        self.title = Self.string(data["titulo"]) ?? "Sin título"
        self.platform = Self.string(data["plataforma"]) ?? "Todas"
        self.poster = Self.string(data["poster"]) ?? ""
        self.backdrop = Self.string(data["backdrop"]) ?? self.poster
        self.stream = Self.string(data["stream"]) ?? ""
        self.description = Self.string(data["desc"]) ?? ""
        let rawEpisodes = (data["capitulos"] as? [Any]) ?? (data["episodios"] as? [Any]) ?? []
        self.episodes = rawEpisodes.enumerated().compactMap { Episode($0.element, fallbackNumber: $0.offset + 1) }
        self.year = Self.string(data["anio"]) ?? Self.string(data["year"]) ?? ""
        self.category = Self.string(data["genero"]) ?? ""
        self.featured = (data["destacado"] as? Bool) ?? false
    }

    var playableURL: URL? {
        guard let url = URL(string: stream), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}
