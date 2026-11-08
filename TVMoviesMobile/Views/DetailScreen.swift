import SwiftUI
import AVKit
import WebKit

private struct PlaybackSelection: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

struct DetailScreen: View {
    let item: CatalogItem
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tvmovies_favorites") private var storedFavorites = "[]"
    @State private var playback: PlaybackSelection?
    @State private var alert: String?

    private var favorites: [String] {
        guard let data = storedFavorites.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private var isFavorite: Bool { favorites.contains(item.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    NetworkPoster(urlString: item.backdrop)
                        .frame(height: 225)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(LinearGradient(colors: [.clear, TVStyle.background], startPoint: .center, endPoint: .bottom))
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.title).font(.system(size: 29, weight: .bold))
                        Text([item.platform, item.year, item.category].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.subheadline).foregroundStyle(TVStyle.muted)
                        Text(item.description.isEmpty ? "Sin descripción disponible." : item.description)
                            .font(.body).foregroundStyle(.white.opacity(0.85))
                        HStack {
                            Button { play(item.stream, title: item.title) } label: {
                                Label("Reproducir", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).padding(13)
                            }
                            .buttonStyle(.borderedProminent).tint(TVStyle.red)
                            Button { toggleFavorite() } label: {
                                Image(systemName: isFavorite ? "checkmark" : "plus")
                                    .frame(width: 42, height: 42)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(isFavorite ? "Quitar de mi lista" : "Agregar a mi lista")
                        }
                        .padding(.vertical, 8)

                        if !item.episodes.isEmpty {
                            Text("Episodios").font(.title2.bold())
                            ForEach(item.episodes) { episode in
                                Button {
                                    play(episode.stream, title: episode.title)
                                } label: {
                                    HStack(spacing: 13) {
                                        Text("\(episode.number)")
                                            .font(.title3.weight(.semibold))
                                            .frame(width: 30)
                                        Text(episode.title)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "play.circle.fill")
                                            .foregroundStyle(TVStyle.red)
                                    }
                                    .padding(15)
                                    .background(TVStyle.secondary, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 30)
            }
            .background(TVStyle.background)
            .scrollIndicators(.hidden)
            .navigationTitle("TVMovies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .fullScreenCover(item: $playback) { selected in
                PlaybackScreen(title: selected.title, url: selected.url)
            }
            .alert("No se puede reproducir", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
                Button("Aceptar", role: .cancel) { alert = nil }
            } message: { Text(alert ?? "") }
        }
    }

    private func play(_ link: String, title: String) {
        guard let url = URL(string: link), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else {
            alert = "No hay un enlace HTTP/HTTPS válido para este contenido."
            return
        }
        playback = PlaybackSelection(title: title, url: url)
    }

    private func toggleFavorite() {
        var next = favorites
        if let index = next.firstIndex(of: item.id) { next.remove(at: index) }
        else { next.append(item.id) }
        guard let data = try? JSONEncoder().encode(next), let string = String(data: data, encoding: .utf8) else { return }
        storedFavorites = string
    }
}

struct PlaybackScreen: View {
    let title: String
    let url: URL
    @Environment(\.dismiss) private var dismiss

    private var isDirectVideo: Bool {
        ["m3u8", "mp4", "m4v", "mov", "mp3"].contains(url.pathExtension.lowercased())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Group {
                if isDirectVideo {
                    NativeVideoPlayer(url: url)
                } else {
                    EmbeddedPlayer(url: url)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(13)
                    .background(.black.opacity(0.78), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .statusBarHidden()
    }
}

private struct NativeVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .onAppear { player.play() }
            .onDisappear { player.pause(); player.replaceCurrentItem(with: nil) }
    }
}

private struct EmbeddedPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
