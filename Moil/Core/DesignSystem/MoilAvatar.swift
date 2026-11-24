import SwiftUI
import UIKit

enum MoilAvatarColor {
    static let blue = Color("AvatarBlue")
    static let red = Color("AvatarRed")
    static let green = Color("AvatarGreen")
    static let orange = Color("AvatarOrange")
    static let yellow = Color("AvatarYellow")
    static let purple = Color("AvatarPurple")
    static let pink = Color("AvatarPink")
}

/// 프로필 아바타입니다. 사진이 있으면 사진을 자르지 않고 원 안에 그대로 보여주고,
/// 없으면 선택한 색의 기본 프로필(얼굴)을 그립니다.
/// 사진을 불러오는 동안에는 같은 자리에 대표색 원을 깔아 두어 깜빡임 없이 바뀌게 합니다.
struct MoilAvatar: View {
    let color: Color
    var size: CGFloat = 56
    /// 서버의 `/images/...` 경로입니다.
    var imagePath: String?
    /// 방금 고른 사진처럼 아직 서버 주소가 없는 이미지를 바로 보여줄 때 씁니다.
    var image: UIImage?

    var body: some View {
        Group {
            if let image {
                photo(Image(uiImage: image))
            } else if let url = MoilProfileImageLoader.url(for: imagePath) {
                MoilRemoteProfileImage(url: url) { phase in
                    switch phase {
                    case .loaded(let loaded): photo(Image(uiImage: loaded))
                    case .loading: Circle().fill(color.opacity(0.35))
                    // 사진이 지워졌거나 받지 못하면 빈 원 대신 기본 프로필을 보여줍니다.
                    case .failed: MoilDefaultAvatar(color: color, size: size)
                    }
                }
            } else {
                MoilDefaultAvatar(color: color, size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("프로필")
    }

    private func photo(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            // 밝은 사진이 배경에 묻히지 않도록 아주 옅은 테두리만 둡니다.
            .overlay { Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5) }
    }
}

extension MoilAvatar {
    init(colorId: String?, imagePath: String?, size: CGFloat = 56) {
        self.init(color: MoilAvatarColor.color(for: colorId), size: size, imagePath: imagePath)
    }
}

/// 사진이 없을 때 쓰는 기본 프로필(색 + 얼굴)입니다.
struct MoilDefaultAvatar: View {
    let color: Color
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(color)

            HStack(spacing: size * 0.18) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
            }
            .offset(y: -size * 0.08)

            Capsule()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.33, height: size * 0.08)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

/// 서버 프로필 사진을 받아 메모리에 보관합니다. 같은 사진이 목록 여러 줄에 나와도 한 번만 받습니다.
@MainActor
enum MoilProfileImageLoader {
    private static let cache = NSCache<NSURL, UIImage>()
    private static var inFlight: [URL: Task<UIImage?, Never>] = [:]

    static func url(for imagePath: String?) -> URL? {
        guard let imagePath, !imagePath.isEmpty else { return nil }
        if imagePath.hasPrefix("http") { return URL(string: imagePath) }
        let trimmed = imagePath.hasPrefix("/") ? String(imagePath.dropFirst()) : imagePath
        return MoilAPIConfiguration.baseURL.appendingPathComponent(trimmed)
    }

    static func cached(_ url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func load(_ url: URL) async -> UIImage? {
        if let cached = cached(url) { return cached }
        if let task = inFlight[url] { return await task.value }
        let task = Task<UIImage?, Never> {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return nil }
            return image
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { cache.setObject(image, forKey: url as NSURL) }
        return image
    }
}

private enum MoilRemoteImagePhase {
    case loading
    case loaded(UIImage)
    case failed
}

private struct MoilRemoteProfileImage<Content: View>: View {
    let url: URL
    @ViewBuilder let content: (MoilRemoteImagePhase) -> Content
    @State private var phase: MoilRemoteImagePhase

    init(url: URL, @ViewBuilder content: @escaping (MoilRemoteImagePhase) -> Content) {
        self.url = url
        self.content = content
        _phase = State(initialValue: MoilProfileImageLoader.cached(url).map { .loaded($0) } ?? .loading)
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                let loaded = await MoilProfileImageLoader.load(url)
                withAnimation(MoilMotion.standard) { phase = loaded.map { .loaded($0) } ?? .failed }
            }
    }
}

#Preview("피그마 프로필") {
    HStack {
        MoilAvatar(color: Color("AvatarGreen"))
        MoilAvatar(color: Color("AvatarBlue"), size: 40)
    }
    .padding()
    .background(MoilColor.background)
}
