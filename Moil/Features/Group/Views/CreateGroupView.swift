import PhotosUI
import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var name = ""
    @State private var didCreateGroup = false
    @State private var errorMessage: String?
    @State private var isCreating = false
    @StateObject private var draft = MoilProfileDraft()
    var onClose: (() -> Void)? = nil
    /// fullScreenCover로 뜬 화면은 루트(MoilApp)의 preferredColorScheme를 항상 물려받지 않을 수 있어,
    /// 여기서도 같은 설정값을 직접 적용합니다.
    @AppStorage("moilDarkMode") private var isDarkMode = false
    var body: some View {
        VStack(spacing: 0) {
            MoilSheetHeader(
                title: "새 그룹 만들기",
                subtitle: "그룹을 만든 뒤 초대 코드로 구성원을 초대할 수 있어요.",
                leading: .back(action: close)
            )
            .safeAreaPadding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("그룹 이름")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.bottom, 10)
                    TextField("예: 우리 가족", text: $name)
                        .moilField()

                    Text("이 그룹에서 쓸 내 프로필")
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

            MoilPrimaryButton(title: "그룹 만들기", isEnabled: canCreate, isLoading: isCreating, action: createGroup)
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
        .alert("그룹을 만들었어요", isPresented: $didCreateGroup) {
            Button("확인", action: close)
        } message: {
            Text("\(name) 그룹의 초대 코드를 구성원에게 공유해보세요.")
        }
        .alert("그룹 생성 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canCreate: Bool { !trimmedName.isEmpty && !isCreating && !draft.isUploading }

    private func createGroup() {
        Task {
            isCreating = true
            defer { isCreating = false }
            do {
                try await groupStore.create(
                    name: trimmedName,
                    nickname: creatorNickname,
                    colorId: draft.requestColorId,
                    imagePath: draft.requestImagePath,
                    using: sessionStore.service()
                )
                didCreateGroup = true
            } catch {
                errorMessage = error.userFacingMessage
            }
        }
    }

    /// 그룹을 만든 사람의 닉네임은 기본 프로필 이름(10자 제한)을, 없으면 "나"를 씁니다.
    private var creatorNickname: String {
        let name = sessionStore.accountProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "나" : String(name.prefix(10))
    }

    /// 계정 기본 프로필(사진 포함)을 이 그룹 프로필의 초기값으로 채웁니다. 사용자가 이미 고른 값은 덮어쓰지 않습니다.
    private func applyDefaultProfile() async {
        await sessionStore.loadAccountProfile()
        guard let profile = sessionStore.accountProfile else { return }
        draft.prefill(colorId: profile.defaultColorId, imagePath: profile.defaultImagePath)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview("새 그룹 만들기") {
    CreateGroupView()
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
}
