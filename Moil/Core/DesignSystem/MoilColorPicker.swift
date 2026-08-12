import SwiftUI

/// 프로필 색을 고르는 공통 컴포넌트입니다. 그룹 만들기와 그룹 참여가 같은 크기와 표시를 씁니다.
struct MoilColorPicker: View {
    let colors: [Color]
    @Binding var selection: Color
    var onAdd: (() -> Void)?

    private let avatarSize: CGFloat = 46
    private let spacing: CGFloat = 16

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(colors, id: \.self) { color in
                Button {
                    // 선택이 즉시 바뀌도록 모션을 끕니다.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { selection = color }
                } label: {
                    MoilAvatar(color: color, size: avatarSize)
                        .overlay {
                            Circle()
                                .stroke(MoilColor.primary, lineWidth: selection == color ? 2 : 0)
                                .padding(-5)
                        }
                        .frame(width: avatarSize + 10, height: avatarSize + 10)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay {
                            Circle().stroke(MoilColor.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }
                        .frame(width: avatarSize + 10, height: avatarSize + 10)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("프로필 추가")
            }
        }
    }
}

#Preview("프로필 색 선택") {
    MoilColorPicker(colors: [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink],
                    selection: .constant(MoilAvatarColor.green), onAdd: {})
        .padding(24)
        .background(MoilColor.background)
}
