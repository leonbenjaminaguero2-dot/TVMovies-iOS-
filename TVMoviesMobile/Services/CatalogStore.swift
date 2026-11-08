import Foundation
import FirebaseCore
import FirebaseFirestore

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var items: [CatalogItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var connected = false

    private var listener: (any ListenerRegistration)?

    func start() {
        guard listener == nil else { return }
        guard FirebaseApp.app() != nil else {
            errorMessage = "Falta configurar Firebase para iOS. Agregá GoogleService-Info.plist al proyecto o al secreto de GitHub."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        // Misma colección que la versión HTML de TVMovies.
        listener = Firestore.firestore().collection("catalogo").addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.connected = false
                    self.errorMessage = "No se pudo leer el catálogo: \(error.localizedDescription)"
                    return
                }
                guard let snapshot else {
                    self.connected = false
                    self.errorMessage = "Firebase devolvió una respuesta vacía."
                    return
                }
                self.items = snapshot.documents.compactMap { CatalogItem(id: $0.documentID, data: $0.data()) }
                    .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
                self.connected = true
                self.errorMessage = nil
            }
        }
    }

    func reconnect() {
        listener?.remove()
        listener = nil
        start()
    }

    func items(for kind: CatalogKind, platform: String, query: String) -> [CatalogItem] {
        items.filter { item in
            item.kind == kind &&
            (kind == .channels || platform == "Todas" || item.platform.caseInsensitiveCompare(platform) == .orderedSame || item.platform == "Todas") &&
            (query.isEmpty || item.title.localizedCaseInsensitiveContains(query))
        }
    }

    var platforms: [String] {
        let actual = Set(items.filter { $0.kind != .channels }.map(\.platform).filter { !$0.isEmpty && $0 != "Todas" && $0 != "Canales" })
        return ["Todas"] + actual.sorted()
    }
}
