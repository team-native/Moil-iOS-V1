import PhotosUI
import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var name = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var didCreateGroup = false
    @State private var errorMessage: String?
    @State private var profileImagePickerItem: PhotosPickerItem?
    @State private var profileImagePreview: Image?
    @State private var uploadedImagePath: String?
    @State private var isUploadingImage = false
    private let colors = [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink]
    var onClose: (() -> Void)? = nil
    var body: some View {
        NavigationStack {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
            TextField("예: 우리 가족", text: $name)
                .moilField()
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 16) {
                ForEach(colors, id: \.self) { color in
                    Button { selectColor(color) } label: {
                        MoilAvatar(color: color, size: 46)
                            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: uploadedImagePath == nil && selectedColor == color ? 2 : 0).padding(-5) }
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
            }
            Text("사진을 선택하면 사진에서 뽑은 색이 내 프로필 색이 돼요.")
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 10)
            Text("그룹을 만든 뒤 초대 코드로 구성원을 초대할 수 있어요.")
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 12)
            Spacer()
            Button("그룹 만들기") {
                Task {
                    do {
                        try await groupStore.create(
                            name: name,
                            nickname: "나",
                            colorId: uploadedImagePath == nil ? MoilAvatarColor.id(for: selectedColor) : nil,
                            imagePath: uploadedImagePath,
                            using: sessionStore.service()
                        )
                        didCreateGroup = true
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14)).safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 12)
        .background(MoilColor.background.ignoresSafeArea())
        .navigationTitle("새 그룹 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: close) {
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
