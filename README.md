# Liner for iOS (Personal Edition)

Ứng dụng phát nhạc cá nhân cho iPhone lấy cảm hứng 100% từ **Liner Desktop (`tryliner/desktop`)**:
- 🎵 **Phát nhạc ngầm không quảng cáo** từ nguồn YouTube Music.
- 🎤 **Lời bài hát đồng bộ mượt mà (Syllable/Karaoke-Synced Lyrics)**: Chữ chạy theo từng âm tiết/từ bằng SwiftUI Masking mượt 120Hz.
- 🌊 **Hiệu ứng nền Fluid Animated Shaders**: Gradient loang màu huyền ảo, mờ chuyển động theo bài hát.
- 📱 **Tích hợp iOS Lock Screen & Dynamic Island**: Điều khiển qua Control Center, tai nghe AirPods.

---

## Cấu trúc dự án
- `.github/workflows/build-ipa.yml`: Tự động build file `.ipa` trên GitHub Actions (macOS runner miễn phí).
- `project.yml`: Cấu hình XcodeGen tạo Xcode project mà không bị lỗi xung đột file `.pbxproj`.
- `LinerApp/`:
  - `LinerApp.swift`: Điểm khởi chạy của ứng dụng.
  - `Info.plist`: Cấu hình quyền chạy nền (`audio`).
  - `Services/`:
    - `AudioPlayerService.swift`: Trình phát `AVPlayer`, kết nối `MPNowPlayingInfoCenter` và `MPRemoteCommandCenter`.
    - `YouTubeMusicService.swift`: Tìm kiếm bài hát và lấy link stream nhạc.
    - `LyricsService.swift`: Kết nối API lời bài hát `lrclib.net` và parse timestamp.
  - `Views/`:
    - `ContentView.swift`: Giao diện tìm kiếm, danh sách bài hát, mini player.
    - `NowPlayingView.swift`: Giao diện phát toàn màn hình với nền fluid shader.
    - `SyllableLyricsView.swift`: Giao diện lời bài hát chạy chữ karaoke.
