import Foundation
import AVFoundation
import MediaPlayer
import Combine

public class AudioPlayerService: ObservableObject {
    public static let shared = AudioPlayerService()

    @Published public var currentTrack: Track?
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var lyrics: [LyricLine] = []
    @Published public var isLoading: Bool = false

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAudioSession()
        setupRemoteCommands()
    }

    public func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate AVAudioSession: \(error)")
        }
    }

    public func playTrack(_ track: Track) {
        isLoading = true
        currentTrack = track
        lyrics = []
        currentTime = 0.0
        duration = track.durationSeconds

        Task {
            // Fetch stream URL and lyrics in parallel
            async let streamTask = YouTubeMusicService.shared.getAudioStreamUrl(videoId: track.id)
            async let lyricsTask = LyricsService.shared.fetchLyrics(
                trackTitle: track.title,
                artistName: track.artist,
                duration: track.durationSeconds
            )

            let (streamUrl, fetchedLyrics) = await (streamTask, lyricsTask)

            await MainActor.run {
                self.lyrics = fetchedLyrics
                self.isLoading = false

                guard let stream = streamUrl, let url = URL(string: stream) else {
                    print("Could not resolve stream URL for \(track.title)")
                    return
                }

                self.startPlayback(url: url, track: track)
            }
        }
    }

    private func startPlayback(url: URL, track: Track) {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        let playerItem = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        // 60fps observer (1/60s) for silky-smooth karaoke highlight
        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let itemDuration = self.player?.currentItem?.duration.seconds, !itemDuration.isNaN {
                self.duration = itemDuration
            }
        }

        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    public func togglePlayPause() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    public func seek(to seconds: Double) {
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 1000)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
        updateNowPlayingInfo()
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    info[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }.resume()
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
