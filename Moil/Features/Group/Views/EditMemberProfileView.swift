import PhotosUI
import SwiftUI

/// 그룹 안에서 내 닉네임/색상/프로필 사진을 수정하는 화면입니다.
/// 색상·사진 선택 UI는 CreateGroupView/GroupJoinProfileView와 동일한 패턴을 씁니다.
struct EditMemberProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let groupId: String
    @State private var nickname: String
    @State private var selectedColor: Color
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var profileImagePickerItem: PhotosPickerItem?
    @State private var profileImagePreview: Image?
    @State private var uploadedImagePath: String?
    @State private var isUploadingImage = false
    private let colors = [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink]

    init(groupId: String, currentNickname: String, currentColorId: String?) {
        self.groupId = groupId
        _nickname = State(initialValue: currentNickname)
        _selectedColor = State(initialValue: MoilAvatarColor.color(for: currentColorId))
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidNickname: Bool {
        (1...10).contains(trimmedNickname.count)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("닉네임").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
                TextField("닉네임 입력", text: $nickname).moilField()
                    .onChange(of: nickname) { _, value in
                        if value.count > 10 { nickname = String(value.prefix(10)) }
                    }
                if !nickname.isEmpty && !isValidNickname {
                    Text("닉네임은 1자 이상 10자 이하로 입력해주세요.")
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.error)
                        .padding(.top, 6)
                }
                Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
                HStack(spacing: 16) {
                    if uploadedImagePath == nil {
                        ForEach(colors, id: \.self) { color in
                            Button { selectColor(color) } label: {
                                MoilAvatar(color: color, size: 46)
                                    .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: selectedColor == color ? 2 : 0).padding(-5) }
                            }
                        }
                    }
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
                    if uploadedImagePath != nil {
                        Button("색상으로 변경") { selectColor(selectedColor) }
                            .font(MoilTypography.regular(13))
                            .foregroundStyle(MoilColor.textSecondary)
                    }
                }
                if uploadedImagePath == nil {
                    Text("사진을 선택하면 사진에서 뽑은 색이 내 프로필 색이 돼요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                        .padding(.top, 10)
                }
                Spacer()
                Button("저장하기") {
                    Task {
                        isSaving = true
                        defer { isSaving = false }
                        do {
                            try await groupStore.updateMyProfile(
                                groupId: groupId,
                                nickname: trimmedNickname,
                                colorId: uploadedImagePath == nil ? MoilAvatarColor.id(for: selectedColor) : nil,
                                imagePath: uploadedImagePath,
                                using: sessionStore.service()
                            )
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
            .navigationTitle("프로필 수정")
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

    private func selectColor(_ color: Color) {
        selectedColor = color
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
    EditMemberProfileView(groupId: "1", currentNickname: "나", currentColorId: "GREEN")
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
}
