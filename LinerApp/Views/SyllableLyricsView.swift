import SwiftUI

public struct SyllableWordView: View {
    public let word: LyricWord
    public let currentTime: Double

    public var progress: CGFloat {
        if currentTime <= word.startTime { return 0.0 }
        if currentTime >= word.endTime { return 1.0 }
        let duration = max(0.01, word.endTime - word.startTime)
        return CGFloat((currentTime - word.startTime) / duration)
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            // Background Dimmed Text
            Text(word.text)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.35))

            // Animated Highlight Mask
            Text(word.text)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * progress)
                    }
                )
        }
    }
}

public struct SyllableLyricsView: View {
    @ObservedObject var player = AudioPlayerService.shared

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Spacer().frame(height: 120)

                    ForEach(player.lyrics) { line in
                        let isActive = player.currentTime >= line.startTime && player.currentTime <= line.endTime
                        let isPast = player.currentTime > line.endTime

                        VStack(alignment: .leading, spacing: 6) {
                            if !line.words.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(line.words) { word in
                                        SyllableWordView(word: word, currentTime: player.currentTime)
                                    }
                                }
                            } else {
                                Text(line.text)
                                    .font(.system(size: isActive ? 28 : 22, weight: .bold, design: .rounded))
                                    .foregroundColor(isActive ? .white : (isPast ? .white.opacity(0.4) : .white.opacity(0.25)))
                            }
                        }
                        .id(line.id)
                        .scaleEffect(isActive ? 1.05 : 1.0)
                        .blur(radius: isActive ? 0 : 0.4)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActive)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            player.seek(to: line.startTime)
                        }
                    }

                    Spacer().frame(height: 180)
                }
                .padding(.horizontal, 28)
            }
            .onChange(of: player.currentTime) { newTime in
                if let activeLine = player.lyrics.first(where: { newTime >= $0.startTime && newTime <= $0.endTime }) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(activeLine.id, anchor: .center)
                    }
                }
            }
        }
    }
}

// Simple FlowLayout for wrapping lyric words across lines
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentPoint = CGPoint.zero
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentPoint.x + size.width > width && currentPoint.x > 0 {
                currentPoint.x = 0
                currentPoint.y += size.height + spacing
            }
            currentPoint.x += size.width + spacing
            maxY = max(maxY, currentPoint.y + size.height)
        }

        return CGSize(width: width, height: maxY)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentPoint = bounds.origin

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentPoint.x + size.width > bounds.maxX && currentPoint.x > bounds.minX {
                currentPoint.x = bounds.minX
                currentPoint.y += size.height + spacing
            }
            subview.place(at: currentPoint, proposal: ProposedViewSize(size))
            currentPoint.x += size.width + spacing
        }
    }
}
