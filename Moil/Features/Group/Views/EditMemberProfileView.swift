import PhotosUI
import SwiftUI

/// 그룹 안의 참여 프로필, 또는 계정 기본 프로필의 이름/색상/사진을 수정하는 화면입니다.
/// 색상·사진 선택 UI는 CreateGroupView/GroupJoinProfileView와 동일한 패턴을 씁니다.
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
    @State private var selectedColorId: String
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var profileImagePickerItem: PhotosPickerItem?
    @State private var profileImagePreview: Image?
    @State private var uploadedImagePath: String?
    @State private var isUploadingImage = false
    /// 현재 프로필 색이 선택 스와치에 없으면(사진에서 자동 추출된 27종 팔레트 중 하나라면)
    /// 맨 앞에 그 색을 추가해, 재진입했을 때 항상 현재 색이 선택 표시된 채로 보이게 합니다.
    private var colorIds: [String] {
        guard !MoilAvatarColor.selectableIds.contains(selectedColorId) else { return MoilAvatarColor.selectableIds }
        return [selectedColorId] + MoilAvatarColor.selectableIds
    }

    init(target: Target, currentNickname: String, currentColorId: String?) {
        self.target = target
        _nickname = State(initialValue: currentNickname)
        _selectedColorId = State(initialValue: currentColorId?.uppercased() ?? "GREEN")
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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(isAccount ? "이름" : "닉네임").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
                TextField(isAccount ? "이름 입력" : "닉네임 입력", text: $nickname).moilField()
                    .onChange(of: nickname) { _, value in
                        if value.count > maxLength { nickname = String(value.prefix(maxLength)) }
                    }
                if !nickname.isEmpty && !isValidNickname {
                    Text(isAccount ? "이름을 입력해주세요." : "닉네임은 1자 이상 10자 이하로 입력해주세요.")
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.error)
                        .padding(.top, 6)
                }
                Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 18)
                if uploadedImagePath == nil {
                    ProfileColorSwatchGrid(colorIds: colorIds, selectedId: selectedColorId, onSelect: selectColor) {
                        profileImagePicker
                    }
                } else {
                    HStack(spacing: 16) {
                        profileImagePicker
                        Button("색상으로 변경") { selectColor(selectedColorId) }
                            .font(MoilTypography.regular(13))
                            .foregroundStyle(MoilColor.textSecondary)
                    }
                }
                if uploadedImagePath == nil {
                    Text("사진을 선택하면 사진에서 뽑은 색이 내 프로필 색이 돼요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                        .padding(.top, 18)
                }
                Text(isAccount ? "기본 프로필은 새 그룹을 만들거나 참여할 때 처음 값으로 쓰여요. 이미 참여한 그룹의 프로필은 바뀌지 않아요." : "이 그룹에서만 보이는 프로필이에요. 기본 프로필은 바뀌지 않아요.")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 12)
                Spacer()
                Button("저장하기") {
                    Task {
                        isSaving = true
                        defer { isSaving = false }
                        do {
                            let colorId = uploadedImagePath == nil ? selectedColorId : nil
                            switch target {
                            case .group(let groupId):
                                try await groupStore.updateMyProfile(
                                    groupId: groupId,
                                    nickname: trimmedNickname,
                                    colorId: colorId,
                                    imagePath: uploadedImagePath,
                                    using: sessionStore.service()
                                )
                            case .account:
                                try await sessionStore.updateDefaultProfile(name: trimmedNickname, colorId: colorId, imagePath: uploadedImagePath)
                            }
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                    .disabled(!isValidNickname || isSaving)
                    .font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                    .background(!isValidNickname || isSaving ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14)).safeAreaPadding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .safeAreaPadding(.top, 12)
            .background(MoilColor.background.ignoresSafeArea())
            .navigationTitle(isAccount ? "기본 프로필 수정" : "그룹 프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                    }
                }
            }
        }
        .onChange(of: profileImagePickerItem) { _, item in
            guard let item else { return }
            uploadProfileImage(item)
        }
        .alert("프로필 수정 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var profileImagePicker: some View {
        PhotosPicker(selection: $profileImagePickerItem, matching: .images) {
            ZStack {
                if let profileImagePreview {
                    profileImagePreview
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(width: 40, height: 40)
                        .overlay { Circle().stroke(MoilColor.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3])) }
                }
                if isUploadingImage {
                    Circle().fill(.black.opacity(0.35)).frame(width: 40, height: 40)
                    ProgressView().tint(.white)
                }
            }
            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: uploadedImagePath != nil ? 2 : 0).padding(-5) }
        }
        .disabled(isUploadingImage)
        .accessibilityLabel("프로필 사진 추가")
    }

    private func selectColor(_ id: String) {
        selectedColorId = id
        uploadedImagePath = nil
        profileImagePreview = nil
        profileImagePickerItem = nil
    }

    private func uploadProfileImage(_ item: PhotosPickerItem) {
        Task {
            isUploadingImage = true
            defer { isUploadingImage = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else {
                    errorMessage = "이미지를 불러오지 못했어요."
                    return
                }
                profileImagePreview = Image(uiImage: uiImage)
                guard let jpegData = MoilProfileImageEncoder.jpegData(from: uiImage) else {
                    errorMessage = "이미지를 처리하지 못했어요."
                    return
                }
                uploadedImagePath = try await sessionStore.service().uploadProfileImage(data: jpegData, filename: "profile.jpg", mimeType: "image/jpeg")
            } catch {
                profileImagePreview = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview("프로필 수정") {
    EditMemberProfileView(target: .group("1"), currentNickname: "나", currentColorId: "GREEN")
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
}
