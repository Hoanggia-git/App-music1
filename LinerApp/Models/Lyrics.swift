import Foundation

public struct LyricWord: Identifiable, Codable, Equatable {
    public var id = UUID()
    public let text: String
    public let startTime: Double
    public let endTime: Double

    public init(text: String, startTime: Double, endTime: Double) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct LyricLine: Identifiable, Codable, Equatable {
    public var id = UUID()
    public let startTime: Double
    public let endTime: Double
    public let text: String
    public var words: [LyricWord]

    public init(startTime: Double, endTime: Double, text: String, words: [LyricWord] = []) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.words = words
    }
}
