import Foundation

public struct Track: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String?
    public let durationSeconds: Double
    public let coverUrl: String?
    public var streamUrl: String?

    public init(
        id: String,
        title: String,
        artist: String,
        album: String? = nil,
        durationSeconds: Double = 0,
        coverUrl: String? = nil,
        streamUrl: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.durationSeconds = durationSeconds
        self.coverUrl = coverUrl
        self.streamUrl = streamUrl
    }
}
