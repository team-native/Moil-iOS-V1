import PhotosUI
import SwiftUI

/// 그룹 안의 참여 프로필, 또는 계정 기본 프로필의 이름/사진/기본 프로필을 수정하는 화면입니다.
/// 사진·기본 프로필 선택은 그룹 만들기/참여 화면과 같은 `ProfilePickerSection`을 씁니다.
struct EditMemberProfileView: View {
    enum Target {
        /// 특정 그룹에서만 쓰는 참여 프로필
        case group(String)
        /// 새 그룹에 들어갈 때 초기값이 되는 계정 기본 프로필
        case account
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let target: Target
    @State private var nickname: String
    @StateObject private var draft: MoilProfileDraft
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(target: Target, currentNickname: String, currentColorId: String?, currentImagePath: String? = nil) {
        self.target = target
        _nickname = State(initialValue: currentNickname)
        _draft = StateObject(wrappedValue: MoilProfileDraft(colorId: currentColorId, imagePath: currentImagePath))
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAccount: Bool {
        if case .account = target { return true }
        return false
    }

    /// 서버 제한: 그룹 닉네임 10자, 계정 이름 100자
    private var maxLength: Int { isAccount ? 100 : 10 }

    private var isValidNickname: Bool {
        (1...maxLength).contains(trimmedNickname.count)
    }

    private var canSave: Bool { isValidNickname && !isSaving && !draft.isUploading }

    var body: some View {
        VStack(spacing: 0) {
            MoilSheetHeader(
                title: isAccount ? "기본 프로필 수정" : "그룹 프로필 수정",
                subtitle: isAccount
                    ? "새 그룹을 만들거나 참여할 때 처음 값으로 쓰여요. 이미 참여한 그룹의 프로필은 바뀌지 않아요."
                    : "이 그룹에서만 보이는 프로필이에요. 기본 프로필은 바뀌지 않아요.",
                leading: .cancel(action: dismiss.callAsFunction)
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ProfilePickerSection(draft: draft)

                    Text(isAccount ? "이름" : "닉네임")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 32)
                        .padding(.bottom, 10)
                    MoilValidatedField(state: nicknameState) {
                        TextField(isAccount ? "이름 입력" : "닉네임 입력", text: $nickname)
                            .moilField()
                    }
                    .onChange(of: nickname) { _, value in
                        if value.count > maxLength { nickname = String(value.prefix(maxLength)) }
                    }
                }
                .padding(.horizontal, MoilSheetHeader.horizontalPadding)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            MoilPrimaryButton(title: "저장하기", isEnabled: canSave, isLoading: isSaving, action: save)
                .padding(.horizontal, MoilSheetHeader.horizontalPadding)
                .padding(.bottom, 12)
        }
        .background(MoilColor.background.ignoresSafeArea())
        .onChange(of: draft.pickerItem) { _, item in
            guard let item else { return }
            Task {
                do { try await draft.upload(item, using: sessionStore.service()) }
                catch { errorMessage = error.userFacingMessage }
            }
        }
        .alert("프로필 수정 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var nicknameState: MoilFieldState {
        guard !nickname.isEmpty, !isValidNickname else { return .neutral }
        return .failure(isAccount ? "이름을 입력해주세요." : "닉네임은 1자 이상 10자 이하로 입력해주세요.")
    }

    private func save() {
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                switch target {
                case .group(let groupId):
                    try await groupStore.updateMyProfile(
                        groupId: groupId,
                        nickname: trimmedNickname,
                        colorId: draft.requestColorId,
                        imagePath: draft.requestImagePath,
                        using: sessionStore.service()
                    )
                case .account:
                    try await sessionStore.updateDefaultProfile(
                        name: trimmedNickname,
                        colorId: draft.requestColorId,
                        imagePath: draft.requestImagePath
                    )
                }
                dismiss()
            } catch {
                errorMessage = error.userFacingMessage
            }
        }
    }
}

#Preview("프로필 수정") {
    EditMemberProfileView(target: .group("1"), currentNickname: "나", currentColorId: "GREEN")
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
}
