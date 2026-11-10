import Foundation

public class YouTubeMusicService {
    public static let shared = YouTubeMusicService()
    private init() {}

    private let instances = [
        "https://pipedapi.kavin.rocks",
        "https://api.piped.privacy.com.de",
        "https://piped-api.garudalinux.org"
    ]

    public func search(query: String) async -> [Track] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        for instance in instances {
            let urlString = "\(instance)/search?q=\(encoded)&filter=music_songs"
            guard let url = URL(string: urlString) else { continue }

            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 6
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    var tracks: [Track] = []
                    for item in items {
                        guard let urlPath = item["url"] as? String,
                              let videoId = urlPath.components(separatedBy: "=").last,
                              let title = item["title"] as? String,
                              let uploaderName = item["uploaderName"] as? String else { continue }

                        let duration = Double(item["duration"] as? Int ?? 0)
                        let thumbnail = item["thumbnail"] as? String

                        tracks.append(Track(
                            id: videoId,
                            title: title,
                            artist: uploaderName,
                            durationSeconds: duration,
                            coverUrl: thumbnail
                        ))
                    }
                    if !tracks.isEmpty { return tracks }
                }
            } catch {
                continue
            }
        }

        return []
    }

    public func getAudioStreamUrl(videoId: String) async -> String? {
        for instance in instances {
            let urlString = "\(instance)/streams/\(videoId)"
            guard let url = URL(string: urlString) else { continue }

            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 8
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let audioStreams = json["audioStreams"] as? [[String: Any]] {
                    // Prefer M4A / AAC for native iOS AVPlayer compatibility
                    let sortedStreams = audioStreams.sorted { s1, s2 in
                        let b1 = s1["bitrate"] as? Int ?? 0
                        let b2 = s2["bitrate"] as? Int ?? 0
                        return b1 > b2
                    }

                    if let m4a = sortedStreams.first(where: { ($0["format"] as? String) == "M4A" }),
                       let streamUrl = m4a["url"] as? String {
                        return streamUrl
                    }

                    if let first = sortedStreams.first, let streamUrl = first["url"] as? String {
                        return streamUrl
                    }
                }
            } catch {
                continue
            }
        }
        return nil
    }
}
