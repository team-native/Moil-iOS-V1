import Combine
import PhotosUI
import SwiftUI
import UIKit

/// 사진에서 대표색을 뽑습니다. 서버(`ProfileColorExtractor.kt`)와 같은 방식
/// (픽셀 3개 묶음 k-means → 가장 큰 묶음의 중심 → 가장 가까운 팔레트 색)으로 계산해,
/// 저장하기 전에도 서버가 정할 색을 미리 보여줍니다. 최종 색은 저장 응답의 값을 씁니다.
enum MoilProfileColorExtractor {
    private static let sampleSide = 64
    private static let clusterCount = 3
    private static let maxIterations = 10

    static func dominantColorId(of image: UIImage) -> String? {
        guard let pixels = samplePixels(image), !pixels.isEmpty else { return nil }
        let centroid = largestClusterCentroid(pixels)
        return MoilAvatarColor.nearestId(
            red: Int(centroid.0.rounded()),
            green: Int(centroid.1.rounded()),
            blue: Int(centroid.2.rounded())
        )
    }

    private typealias Pixel = (Double, Double, Double)

    private static func samplePixels(_ image: UIImage) -> [Pixel]? {
        guard let cgImage = image.cgImage else { return nil }
        let side = sampleSide
        var buffer = [UInt8](repeating: 0, count: side * side * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return nil }
        var pixels: [Pixel] = []
        pixels.reserveCapacity(side * side)
        for index in stride(from: 0, to: buffer.count, by: 4) where buffer[index + 3] >= 128 {
            pixels.append((Double(buffer[index]), Double(buffer[index + 1]), Double(buffer[index + 2])))
        }
        return pixels
    }

    private static func distance(_ a: Pixel, _ b: Pixel) -> Int {
        let r = Int(a.0.rounded()) - Int(b.0.rounded())
        let g = Int(a.1.rounded()) - Int(b.1.rounded())
        let bl = Int(a.2.rounded()) - Int(b.2.rounded())
        return r * r + g * g + bl * bl
    }

    private static func largestClusterCentroid(_ pixels: [Pixel]) -> Pixel {
        let count = min(clusterCount, pixels.count)
        var centroids: [Pixel] = [pixels[0]]
        while centroids.count < count {
            let next = pixels.max { lhs, rhs in
                centroids.map { distance(lhs, $0) }.min()! < centroids.map { distance(rhs, $0) }.min()!
            }!
            centroids.append(next)
        }
        var assignments = [Int](repeating: 0, count: pixels.count)
        for _ in 0..<maxIterations {
            let next = pixels.map { pixel in
                centroids.indices.min { distance(pixel, centroids[$0]) < distance(pixel, centroids[$1]) }!
            }
            var sums = [Pixel](repeating: (0, 0, 0), count: centroids.count)
            var counts = [Int](repeating: 0, count: centroids.count)
            for (index, cluster) in next.enumerated() {
                sums[cluster].0 += pixels[index].0
                sums[cluster].1 += pixels[index].1
                sums[cluster].2 += pixels[index].2
                counts[cluster] += 1
            }
            let nextCentroids: [Pixel] = centroids.indices.map { cluster in
                guard counts[cluster] > 0 else { return centroids[cluster] }
                let n = Double(counts[cluster])
                return (sums[cluster].0 / n, sums[cluster].1 / n, sums[cluster].2 / n)
            }
            assignments = next
            let converged = zip(nextCentroids, centroids).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 && $0.2 == $1.2 }
            centroids = nextCentroids
            if converged { break }
        }
        let largest = centroids.indices.max { lhs, rhs in
            assignments.filter { $0 == lhs }.count < assignments.filter { $0 == rhs }.count
        }!
        return centroids[largest]
    }
}

/// 프로필 고르기 화면들(그룹 만들기·참여·프로필 수정)이 같이 쓰는 선택 상태입니다.
/// 사진을 고르면 사진을 그대로 프로필로 쓰고, 사진의 대표색을 프로필 색으로 씁니다.
/// 사진을 쓰지 않을 때는 기본 프로필(색 + 얼굴) 중 하나를 고릅니다.
@MainActor
final class MoilProfileDraft: ObservableObject {
    @Published private(set) var colorId: String
    /// 서버에 올라간 사진 경로(`/images/...`)입니다. 기존 사진이거나 방금 올린 사진입니다.
    @Published private(set) var imagePath: String?
    /// 방금 고른 사진입니다. 업로드가 끝나기 전에도 바로 보여줍니다.
    @Published private(set) var localImage: UIImage?
    @Published private(set) var isUploading = false
    @Published var pickerItem: PhotosPickerItem?
    private var userTouched = false

    init(colorId: String? = nil, imagePath: String? = nil) {
        self.colorId = colorId?.uppercased().nilIfEmpty ?? "GREEN"
        self.imagePath = imagePath?.nilIfEmpty
    }

    var hasPhoto: Bool { imagePath != nil || localImage != nil }
    var color: Color { MoilAvatarColor.color(for: colorId) }
    /// 사진을 쓰면 색은 비워 보내 서버가 사진에서 대표색을 정하게 합니다.
    var requestColorId: String? { imagePath == nil ? colorId : nil }
    var requestImagePath: String? { imagePath }

    /// 기본 프로필 값으로 채웁니다. 사용자가 이미 직접 고른 뒤라면 덮어쓰지 않습니다.
    func prefill(colorId: String?, imagePath: String?) {
        guard !userTouched else { return }
        if let colorId = colorId?.uppercased().nilIfEmpty { self.colorId = colorId }
        self.imagePath = imagePath?.nilIfEmpty
    }

    func selectDefault(_ id: String) {
        userTouched = true
        colorId = id
        imagePath = nil
        localImage = nil
        pickerItem = nil
    }

    func removePhoto() {
        userTouched = true
        imagePath = nil
        localImage = nil
        pickerItem = nil
        if !MoilAvatarColor.selectableIds.contains(colorId) {
            colorId = MoilAvatarColor.selectableIds.first ?? "GREEN"
        }
    }

    /// 고른 사진을 바로 보여주고 대표색을 계산한 뒤 서버에 올립니다. 실패하면 이전 상태로 되돌립니다.
    func upload(_ item: PhotosPickerItem, using service: MoilAPIService) async throws {
        userTouched = true
        let previous = (colorId, imagePath, localImage)
        isUploading = true
        defer { isUploading = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                throw MoilProfileDraftError.unreadableImage
            }
            withAnimation(.easeOut(duration: 0.2)) { localImage = image }
            if let extracted = await Task.detached(priority: .userInitiated, operation: {
                MoilProfileColorExtractor.dominantColorId(of: image)
            }).value {
                withAnimation(.easeOut(duration: 0.2)) { colorId = extracted }
            }
            guard let jpeg = MoilProfileImageEncoder.jpegData(from: image) else {
                throw MoilProfileDraftError.unprocessableImage
            }
            imagePath = try await service.uploadProfileImage(data: jpeg, filename: "profile.jpg", mimeType: "image/jpeg")
        } catch {
            (colorId, imagePath, localImage) = previous
            pickerItem = nil
            throw error
        }
    }
}

enum MoilProfileDraftError: LocalizedError {
    case unreadableImage
    case unprocessableImage

    var errorDescription: String? {
        switch self {
        case .unreadableImage: "사진을 불러오지 못했어요."
        case .unprocessableImage: "사진을 처리하지 못했어요."
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// 프로필 미리보기 + 사진 선택 + 기본 프로필 목록입니다.
struct ProfilePickerSection: View {
    @ObservedObject var draft: MoilProfileDraft
    var previewSize: CGFloat = 84

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    private var defaultIds: [String] {
        let ids = MoilAvatarColor.selectableIds
        guard !draft.hasPhoto, !ids.contains(draft.colorId) else { return ids }
        return [draft.colorId] + ids
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                preview
                VStack(alignment: .leading, spacing: 0) {
                    Text(draft.hasPhoto ? "사진 프로필" : "기본 프로필")
                        .font(MoilTypography.bold(16))
                        .foregroundStyle(MoilColor.textPrimary)
                    if draft.hasPhoto {
                        HStack(spacing: 6) {
                            Circle().fill(draft.color).frame(width: 10, height: 10)
                            Text("대표색 · \(MoilAvatarColor.name(for: draft.colorId))")
                                .font(MoilTypography.semibold(13))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                        .padding(.top, 6)
                    }
                    Text(draft.hasPhoto
                         ? "사진에서 뽑은 대표색이 일정과 멤버 표시에 쓰여요."
                         : "사진을 올리면 사진 그대로 프로필이 되고, 대표색이 자동으로 정해져요.")
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    HStack(spacing: 8) {
                        PhotosPicker(selection: $draft.pickerItem, matching: .images) {
                            chip(draft.hasPhoto ? "사진 변경" : "사진 선택", systemImage: "photo", isProminent: true)
                        }
                        .disabled(draft.isUploading)
                        if draft.hasPhoto {
                            Button { withAnimation(.easeOut(duration: 0.2)) { draft.removePhoto() } } label: {
                                chip("사진 삭제", systemImage: nil, isProminent: false)
                            }
                            .disabled(draft.isUploading)
                        }
                    }
                    .padding(.top, 12)
                }
            }

            Text("기본 프로필 선택")
                .font(MoilTypography.semibold(12))
                .foregroundStyle(MoilColor.textTertiary)
                .padding(.top, 28)
                .padding(.bottom, 14)

            let selectedDefaultId = draft.hasPhoto ? nil : draft.colorId
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(defaultIds, id: \.self) { id in
                    let isSelected = selectedDefaultId == id
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { draft.selectDefault(id) }
                    } label: {
                        MoilDefaultAvatar(color: MoilAvatarColor.color(for: id), size: 40)
                            .padding(4)
                            .overlay { Circle().strokeBorder(MoilColor.textPrimary, lineWidth: isSelected ? 2 : 0) }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("기본 프로필 \(MoilAvatarColor.name(for: id))")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var preview: some View {
        ZStack {
            MoilAvatar(color: draft.color, size: previewSize, imagePath: draft.imagePath, image: draft.localImage)
            if draft.isUploading {
                Circle().fill(.black.opacity(0.35)).frame(width: previewSize, height: previewSize)
                ProgressView().tint(.white)
            }
        }
        // 사진일 때는 대표색 고리를 둘러, 고른 사진과 대표색이 어떻게 이어지는지 바로 보이게 합니다.
        .padding(4)
        .overlay { Circle().strokeBorder(draft.color, lineWidth: draft.hasPhoto ? 3 : 0) }
        .animation(.easeOut(duration: 0.2), value: draft.colorId)
    }

    private func chip(_ title: String, systemImage: String?, isProminent: Bool) -> some View {
        HStack(spacing: 5) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 12, weight: .semibold)) }
            Text(title).font(MoilTypography.semibold(13))
        }
        .foregroundStyle(isProminent ? MoilColor.primary : MoilColor.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(isProminent ? MoilColor.primary.opacity(0.12) : MoilColor.textPrimary.opacity(0.06))
        .clipShape(Capsule())
    }
}
