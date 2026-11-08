import SwiftUI
import FirebaseCore

@main
struct TVMoviesApp: App {
    @StateObject private var catalog = CatalogStore()

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootScreen()
                .environmentObject(catalog)
                .preferredColorScheme(.dark)
                .onAppear { catalog.start() }
        }
    }
}
