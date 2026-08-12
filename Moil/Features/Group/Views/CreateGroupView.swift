import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var name = ""
    @State private var selectedColor = MoilAvatarColor.green
    @State private var didCreateGroup = false
    @State private var isAdditionalProfilePresented = false
    @State private var errorMessage: String?
    private let colors = [MoilAvatarColor.green, MoilAvatarColor.purple, MoilAvatarColor.pink]
    var onClose: (() -> Void)? = nil
    var body: some View {
        NavigationStack {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
            MoilTextField(placeholder: "예: 우리 가족", text: $name)
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 16) {
                ForEach(colors, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        MoilAvatar(color: color, size: 46)
                            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: selectedColor == color ? 2 : 0).padding(-5) }
                    }
                }
                Button { isAdditionalProfilePresented = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(width: 40, height: 40)
                        .overlay { Circle().stroke(MoilColor.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3])) }
                }
                .accessibilityLabel("프로필 추가")
            }
            Text("그룹을 만든 뒤 초대 코드로 구성원을 초대할 수 있어요.")
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 22)
            Spacer()
            MoilButton(title: "그룹 만들기", isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                Task {
                    do {
                        try await groupStore.create(name: name, nickname: "나", colorId: MoilAvatarColor.id(for: selectedColor), using: sessionStore.service())
                        didCreateGroup = true
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
                .safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
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
        .alert("그룹을 만들었어요", isPresented: $didCreateGroup) {
            Button("확인", action: close)
        } message: {
            Text("\(name) 그룹의 초대 코드를 구성원에게 공유해보세요.")
        }
        .alert("프로필 추가", isPresented: $isAdditionalProfilePresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("새 프로필은 그룹 생성 후에도 추가할 수 있어요.")
        }
        .alert("그룹 생성 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
}
