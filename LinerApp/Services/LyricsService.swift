import Foundation

public class LyricsService {
    public static let shared = LyricsService()
    private init() {}

    public func fetchLyrics(trackTitle: String, artistName: String, duration: Double) async -> [LyricLine] {
        guard let encodedTitle = trackTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let urlString = "https://lrclib.net/api/get?track_name=\(encodedTitle)&artist_name=\(encodedArtist)&duration=\(Int(duration))"
        guard let url = URL(string: urlString) else { return [] }

        do {
            var request = URLRequest(url: url)
            request.setValue("Liner-iOS/1.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let synced = json["syncedLyrics"] as? String {
                return parseLRC(synced)
            }
        } catch {
            print("Lyrics fetch error: \(error)")
        }

        return []
    }

    public func parseLRC(_ lrcContent: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let rawLines = lrcContent.components(separatedBy: .newlines)

        var parsedEntries: [(time: Double, text: String)] = []

        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[") else { continue }

            if let closingBracketIndex = trimmed.firstIndex(of: "]") {
                let timeString = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closingBracketIndex])
                let text = String(trimmed[trimmed.index(after: closingBracketIndex)...]).trimmingCharacters(in: .whitespaces)

                if let time = parseTimestamp(timeString) {
                    parsedEntries.append((time: time, text: text))
                }
            }
        }

        parsedEntries.sort { $0.time < $1.time }

        for i in 0..<parsedEntries.count {
            let current = parsedEntries[i]
            let nextTime = (i + 1 < parsedEntries.count) ? parsedEntries[i + 1].time : (current.time + 4.0)
            let duration = max(0.5, nextTime - current.time)

            // Split into words and distribute duration for karaoke effect
            let rawWords = current.text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            var words: [LyricWord] = []
            if !rawWords.isEmpty {
                let wordDuration = duration / Double(rawWords.count)
                for (wIndex, wText) in rawWords.enumerated() {
                    let wStart = current.time + (Double(wIndex) * wordDuration)
                    let wEnd = wStart + wordDuration
                    words.append(LyricWord(text: wText, startTime: wStart, endTime: wEnd))
                }
            }

            lines.append(LyricLine(
                startTime: current.time,
                endTime: nextTime,
                text: current.text,
                words: words
            ))
        }

        return lines
    }

    private func parseTimestamp(_ str: String) -> Double? {
        let parts = str.components(separatedBy: ":")
        guard parts.count == 2 else { return nil }
        guard let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else { return nil }
        return (minutes * 60.0) + seconds
    }
}
