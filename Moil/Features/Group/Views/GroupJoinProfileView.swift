import SwiftUI

struct GroupJoinProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let onComplete: () -> Void
    @State private var nickname = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var isAdditionalProfilePresented = false
    @State private var isJoining = false
    @State private var errorMessage: String?
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
            HStack(spacing: 10) { AvatarStack(); VStack(alignment: .leading, spacing: 4) { Text(groupStore.pendingInviteGroupName).font(MoilTypography.bold(14)); Text("구성원 \(groupStore.pendingInviteMemberCount)명").font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary) } }
                .padding(13).background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.top, 22)
            MoilFormStack {
                MoilValidatedField(label: "이 그룹에서 사용할 이름") {
                    MoilTextField(placeholder: "닉네임 입력", text: $nickname)
                }
            }
            .padding(.top, MoilTabScreenMetrics.fieldSpacing)
                .onChange(of: nickname) { _, value in
                    if value.count > 10 { nickname = String(value.prefix(10)) }
                }
            if !nickname.isEmpty && !isValidNickname {
                Text("닉네임은 1자 이상 10자 이하로 입력해주세요.")
                    .font(MoilTypography.regular(12))
                    .foregroundStyle(MoilColor.error)
                    .padding(.top, 6)
            }
            Text("이미 사용 중인 프로필").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 16).padding(.bottom, 10)
            HStack(spacing: 14) { ForEach([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green, MoilAvatarColor.orange], id: \.self) { color in MoilAvatar(color: color, size: 34).opacity(0.35) } }
            Text("내 프로필 색 선택")
                .font(MoilTypography.semibold(12))
                .foregroundStyle(MoilColor.textTertiary)
                .padding(.top, MoilTabScreenMetrics.fieldSpacing)
                .padding(.bottom, 18)
            MoilColorPicker(colors: colors, selection: $selectedColor, onAdd: { isAdditionalProfilePresented = true })
            Spacer()
            MoilButton(title: "참여하기", isEnabled: isValidNickname, isLoading: isJoining) {
                guard let inviteCode = groupStore.pendingInviteCode else { return }
                Task {
                    isJoining = true
                    defer { isJoining = false }
                    do {
                        try await groupStore.join(inviteCode: inviteCode, nickname: trimmedNickname, colorId: MoilAvatarColor.id(for: selectedColor), using: sessionStore.service())
                        onComplete()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        .background(MoilColor.background.ignoresSafeArea())
        .alert("프로필 추가", isPresented: $isAdditionalProfilePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("새 프로필은 그룹 참여 후에도 추가할 수 있어요.")
        }
        .alert("그룹 참여 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidNickname: Bool {
        (1...10).contains(trimmedNickname.count)
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
