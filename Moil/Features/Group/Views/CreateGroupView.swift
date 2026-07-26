import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor: Color = .teal
    @State private var didCreateGroup = false
    private let colors: [Color] = [.teal, .purple, .pink]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary)
                        .frame(width: 32, height: 32)
                }
                Text("새 그룹 만들기").font(MoilTypography.bold(22))
            }
            .padding(.top, 24)
            Text("그룹 이름").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 26).padding(.bottom, 10)
            TextField("예: 우리 가족", text: $name)
                .font(MoilTypography.regular(15))
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Text("내 프로필 색 선택").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 18).padding(.bottom, 10)
            HStack(spacing: 16) {
                ForEach(colors, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        Circle().fill(color).frame(width: 46, height: 46)
                            .overlay { Image(systemName: "person.fill").font(.system(size: 16)).foregroundStyle(.white) }
                            .overlay { Circle().stroke(MoilColor.textPrimary, lineWidth: selectedColor == color ? 2 : 0).padding(-5) }
                    }
                }
            }
            Text("그룹을 만든 뒤 초대 코드로 구성원을 초대할 수 있어요.")
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 22)
            Spacer()
            Button("그룹 만들기") { didCreateGroup = true }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .font(MoilTypography.bold(16)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14)).padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(MoilColor.background.ignoresSafeArea())
        .alert("그룹을 만들었어요", isPresented: $didCreateGroup) {
            Button("확인", action: dismiss.callAsFunction)
        } message: {
            Text("\(name) 그룹의 초대 코드를 구성원에게 공유해보세요.")
        }
    }
}
