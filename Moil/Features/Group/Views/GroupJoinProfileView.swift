import PhotosUI
import SwiftUI

struct GroupJoinProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let onComplete: () -> Void
    @State private var nickname = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @StateObject private var draft = MoilProfileDraft()
    /// fullScreenCover로 뜬 화면은 루트(MoilApp)의 preferredColorScheme를 항상 물려받지 않을 수 있어,
    /// 여기서도 같은 설정값을 직접 적용합니다.
    @AppStorage("moilDarkMode") private var isDarkMode = false
    init(onComplete: @escaping () -> Void = {}) { self.onComplete = onComplete }

    var body: some View {
        VStack(spacing: 0) {
            MoilSheetHeader(title: "프로필 설정", leading: .back(action: dismiss.callAsFunction))
                .safeAreaPadding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        AvatarStack()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(groupStore.pendingInviteGroupName).font(MoilTypography.bold(15))
                            Text("구성원 \(groupStore.pendingInviteMemberCount)명")
                                .font(MoilTypography.regular(12))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(MoilColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("이 그룹에서 사용할 이름")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 28)
                        .padding(.bottom, 10)
                    MoilValidatedField(state: nicknameState) {
                        TextField("닉네임 입력", text: $nickname).moilField()
                    }
                    .onChange(of: nickname) { _, value in
                        if value.count > 10 { nickname = String(value.prefix(10)) }
                    }

                    Text("내 프로필")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    ProfilePickerSection(draft: draft)
                }
                .padding(.horizontal, MoilSheetHeader.horizontalPadding)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            MoilPrimaryButton(title: "참여하기", isEnabled: canJoin, isLoading: isJoining, action: join)
                .padding(.horizontal, MoilSheetHeader.horizontalPadding)
                .padding(.bottom, 12)
        }
        .background(MoilColor.background.ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task { await applyDefaultProfile() }
        .onChange(of: draft.pickerItem) { _, item in
            guard let item else { return }
            Task {
                do { try await draft.upload(item, using: sessionStore.service()) }
                catch { errorMessage = error.userFacingMessage }
            }
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

    private var canJoin: Bool { isValidNickname && !isJoining && !draft.isUploading }

    private var nicknameState: MoilFieldState {
        guard !nickname.isEmpty, !isValidNickname else { return .neutral }
        return .failure("닉네임은 1자 이상 10자 이하로 입력해주세요.")
    }

    private func join() {
        guard let inviteCode = groupStore.pendingInviteCode else { return }
        Task {
            isJoining = true
            defer { isJoining = false }
            do {
                try await groupStore.join(
                    inviteCode: inviteCode,
                    nickname: trimmedNickname,
                    colorId: draft.requestColorId,
                    imagePath: draft.requestImagePath,
                    using: sessionStore.service()
                )
                onComplete()
            } catch {
                errorMessage = error.userFacingMessage
            }
        }
    }

    /// 계정 기본 프로필(사진 포함)과 이름을 이 그룹 프로필의 초기값으로 채웁니다. 사용자가 이미 고른 값은 덮어쓰지 않습니다.
    private func applyDefaultProfile() async {
        await sessionStore.loadAccountProfile()
        guard let profile = sessionStore.accountProfile else { return }
        draft.prefill(colorId: profile.defaultColorId, imagePath: profile.defaultImagePath)
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if nickname.isEmpty, !name.isEmpty {
            nickname = String(name.prefix(10))
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
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
}
