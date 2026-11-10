import SwiftUI

public struct ContentView: View {
    @StateObject private var player = AudioPlayerService.shared
    @State private var searchQuery: String = ""
    @State private var searchResults: [Track] = []
    @State private var isSearching: Bool = false
    @State private var showNowPlayingSheet: Bool = false

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.08, green: 0.08, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                HStack {
                    Text("Liner")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search songs, artists on YouTube Music...", text: $searchQuery)
                        .foregroundColor(.white)
                        .onSubmit {
                            performSearch()
                        }
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Results list
                if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Search any track to play with synchronized lyrics")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List(searchResults) { track in
                        Button(action: {
                            player.playTrack(track)
                            showNowPlayingSheet = true
                        }) {
                            HStack(spacing: 14) {
                                if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 52, height: 52)
                                    .cornerRadius(10)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 52, height: 52)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    }
                    .listStyle(.plain)
                }
            }

            // Bottom Mini Player Bar
            if player.currentTrack != nil {
                MiniPlayerBar(onTap: { showNowPlayingSheet = true })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showNowPlayingSheet) {
            NowPlayingView()
        }
    }

    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        Task {
            let results = await YouTubeMusicService.shared.search(query: searchQuery)
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}

public struct MiniPlayerBar: View {
    @ObservedObject var player = AudioPlayerService.shared
    public let onTap: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = player.currentTrack?.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 44, height: 44)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentTrack?.title ?? "")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(player.currentTrack?.artist ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { player.togglePlayPause() }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
        .onTapGesture {
            onTap()
        }
    }
}
