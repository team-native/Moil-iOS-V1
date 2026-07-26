import SwiftUI

struct GroupJoinProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    let onComplete: () -> Void
    @State private var nickname = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var isAdditionalProfilePresented = false
    private let colors = [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink]
    init(onComplete: @escaping () -> Void = {}) { self.onComplete = onComplete }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary).frame(width: 32, height: 32)
                }
                Text("프로필 설정").font(MoilTypography.bold(26))
            }
            .safeAreaPadding(.top, 16)
            HStack(spacing: 10) { AvatarStack(); VStack(alignment: .leading, spacing: 4) { Text("우리 가족").font(MoilTypography.bold(14)); Text("구성원 4명").font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary) } }
                .padding(13).background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.top, 22)
            Text("이 그룹에서 사용할 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            TextField("닉네임 입력", text: $nickname).font(MoilTypography.regular(15)).padding(14).background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            Text("이미 사용 중인 프로필").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 16).padding(.bottom, 10)
            HStack(spacing: 14) { ForEach([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green, MoilAvatarColor.orange], id: \.self) { color in MoilAvatar(color: color, size: 34).opacity(0.35) } }
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 14) {
                ForEach(colors, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        MoilAvatar(color: color, size: 40)
                            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: selectedColor == color ? 2 : 0).padding(-5) }
                    }
                }
                Button { isAdditionalProfilePresented = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(width: 36, height: 36)
                        .overlay { Circle().stroke(MoilColor.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3])) }
                }
                .accessibilityLabel("프로필 추가")
            }
            Spacer()
            Button("참여하기") {
                groupStore.joinGroup(name: "우리 가족", color: selectedColor)
                onComplete()
            }
                .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                .background(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14)).safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(MoilColor.background.ignoresSafeArea())
        .alert("프로필 추가", isPresented: $isAdditionalProfilePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("새 프로필은 그룹 참여 후에도 추가할 수 있어요.")
        }
    }
}
private struct AvatarStack: View {
    var body: some View {
        HStack(spacing: -8) {
            ForEach([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green, MoilAvatarColor.orange], id: \.self) {
                MoilAvatar(color: $0, size: 22)
            }
        }
    }
}

#Preview("그룹 참여 프로필") {
    GroupJoinProfileView()
}
