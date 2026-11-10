import SwiftUI

public struct NowPlayingView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showLyrics: Bool = true
    @State private var backgroundAngle: Double = 0

    public var body: some View {
        ZStack {
            // Fluid Animated Gradient Shader Background
            FluidBackgroundView(angle: backgroundAngle)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        backgroundAngle = 360
                    }
                }

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial))
                    }

                    Spacer()

                    Button(action: { withAnimation(.spring()) { showLyrics.toggle() } }) {
                        Image(systemName: showLyrics ? "quote.bubble.fill" : "quote.bubble")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(showLyrics ? Color.white.opacity(0.25) : Color.clear))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Middle Content: Lyrics or Big Cover Art
                if showLyrics {
                    SyllableLyricsView()
                        .transition(.opacity)
                } else {
                    Spacer()
                    if let coverUrl = player.currentTrack?.coverUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(width: 320, height: 320)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .frame(width: 320, height: 320)
                    }
                    Spacer()
                }

                // Bottom Controls
                VStack(spacing: 16) {
                    // Track Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.currentTrack?.title ?? "No Track Playing")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(player.currentTrack?.artist ?? "")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        Spacer()
                    }

                    // Progress Slider
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { player.seek(to: $0) }
                            ),
                            in: 0...max(1, player.duration)
                        )
                        .tint(.white)

                        HStack {
                            Text(formatTime(player.currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Text(formatTime(player.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    // Playback Buttons
                    HStack(spacing: 48) {
                        Button(action: { player.seek(to: max(0, player.currentTime - 10)) }) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }

                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        }

                        Button(action: { player.seek(to: min(player.duration, player.currentTime + 10)) }) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 28)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// Fluid Shader Simulation using overlapping rotating gradient orbs with heavy blur
public struct FluidBackgroundView: View {
    public let angle: Double

    public var body: some View {
        ZStack {
            Color.black

            Circle()
                .fill(Color(red: 0.8, green: 0.2, blue: 0.4).opacity(0.6))
                .frame(width: 380, height: 380)
                .offset(x: -100, y: -150)
                .rotationEffect(.degrees(angle))

            Circle()
                .fill(Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.6))
                .frame(width: 420, height: 420)
                .offset(x: 120, y: 100)
                .rotationEffect(.degrees(-angle))

            Circle()
                .fill(Color(red: 0.5, green: 0.1, blue: 0.7).opacity(0.5))
                .frame(width: 350, height: 350)
                .offset(x: 0, y: 180)
        }
        .blur(radius: 70)
    }
}
