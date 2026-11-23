import SwiftUI

/// 프로필 색 스와치를 한 줄에 6칸씩 그리는 격자입니다.
/// 그룹 만들기/참여/프로필 수정 화면이 같은 배치를 쓰도록 모았고, 사진 추가 버튼은 `trailing`으로 마지막 칸에 붙입니다.
struct ProfileColorSwatchGrid<Trailing: View>: View {
    let colorIds: [String]
    let selectedId: String?
    var swatchSize: CGFloat = 46
    let onSelect: (String) -> Void
    @ViewBuilder var trailing: () -> Trailing

    /// 좁은 기기(SE 등)에서도 6칸이 한 줄에 들어가도록 칸 너비는 화면에 맞춰 늘고 줄게 둡니다.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(colorIds, id: \.self) { id in
                Button { onSelect(id) } label: {
                    MoilAvatar(color: MoilAvatarColor.color(for: id), size: swatchSize)
                        .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: selectedId == id ? 2 : 0).padding(-5) }
                }
                .accessibilityLabel(MoilAvatarColor.name(for: id))
                .accessibilityAddTraits(selectedId == id ? .isSelected : [])
            }
            trailing()
        }
    }
}
