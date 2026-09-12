import PhotosUI
import SwiftUI

struct GroupJoinProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let onComplete: () -> Void
    @State private var nickname = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var profileImagePickerItem: PhotosPickerItem?
    @State private var profileImagePreview: Image?
    @State private var uploadedImagePath: String?
    @State private var isUploadingImage = false
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
            Text("이 그룹에서 사용할 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
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
            Text("이미 사용 중인 프로필").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 16).padding(.bottom, 10)
            HStack(spacing: 14) { ForEach([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green, MoilAvatarColor.orange], id: \.self) { color in MoilAvatar(color: color, size: 34).opacity(0.35) } }
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 14) {
                ForEach(colors, id: \.self) { color in
                    Button { selectColor(color) } label: {
                        MoilAvatar(color: color, size: 40)
                            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: uploadedImagePath == nil && selectedColor == color ? 2 : 0).padding(-5) }
                    }
                }
                PhotosPicker(selection: $profileImagePickerItem, matching: .images) {
                    ZStack {
                        if let profileImagePreview {
                            profileImagePreview
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(MoilColor.textSecondary)
                                .frame(width: 36, height: 36)
                                .overlay { Circle().stroke(MoilColor.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3])) }
                        }
                        if isUploadingImage {
                            Circle().fill(.black.opacity(0.35)).frame(width: 36, height: 36)
                            ProgressView().tint(.white)
                        }
                    }
                    .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: uploadedImagePath != nil ? 2 : 0).padding(-5) }
                }
                .disabled(isUploadingImage)
                .accessibilityLabel("프로필 사진 추가")
            }
            Text("사진을 선택하면 사진에서 뽑은 색이 내 프로필 색이 돼요.")
                .font(MoilTypography.regular(12))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 8)
            Spacer()
            Button("참여하기") {
                guard let inviteCode = groupStore.pendingInviteCode else { return }
                Task {
                    isJoining = true
                    defer { isJoining = false }
                    do {
                        try await groupStore.join(
                            inviteCode: inviteCode,
                            nickname: trimmedNickname,
                            colorId: uploadedImagePath == nil ? MoilAvatarColor.id(for: selectedColor) : nil,
                            imagePath: uploadedImagePath,
                            using: sessionStore.service()
                        )
                        onComplete()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
                .disabled(!isValidNickname || isJoining)
                .font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                .background(!isValidNickname || isJoining ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14)).safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(MoilColor.background.ignoresSafeArea())
        .onChange(of: profileImagePickerItem) { _, item in
            guard let item else { return }
            uploadProfileImage(item)
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
