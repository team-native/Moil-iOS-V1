import SwiftUI

struct GroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLeavingGroup = false
    private let members: [(String, String, Color)] = [("아빠", "관리자", .blue), ("엄마", "멤버", .red), ("나", "멤버", .green), ("동생", "멤버", .orange)]
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary).frame(width: 36, height: 36).background(.white, in: Circle())
                }
                Spacer()
                Text("그룹 상세").font(MoilTypography.bold(17))
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }.padding(.top, 16).padding(.bottom, 24)
            HStack(spacing: 12) {
                Circle().fill(MoilColor.primary.opacity(0.18)).frame(width: 48, height: 48).overlay { Image(systemName: "person.2.fill").foregroundStyle(MoilColor.primary) }
                VStack(alignment: .leading, spacing: 4) {
                    Text("우리 가족").font(MoilTypography.bold(22))
                    Text("4명의 멤버와 함께하고 있어요").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary)
                }
            }.padding(.bottom, 28)
            Text("구성원").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary)
            VStack(spacing: 0) { ForEach(members.indices, id: \.self) { index in HStack(spacing: 12) { Circle().fill(members[index].2).frame(width: 34, height: 34).overlay { Image(systemName: "person.fill").font(.system(size: 12)).foregroundStyle(.white) }; VStack(alignment: .leading, spacing: 3) { Text(members[index].0).font(MoilTypography.semibold(15)); Text(members[index].1).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }; Spacer() }.padding(14); if index < members.count - 1 { Divider().padding(.leading, 60) } } }.background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            Text("이번 달 일정").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 28)
            Text("7월 일정 5건").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary).frame(maxWidth: .infinity).padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            Button("그룹 나가기") { isLeavingGroup = true }
                .font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.error)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .padding(.top, 28)
        }.padding(.horizontal, 16).padding(.bottom, 32) }.background(MoilColor.background)
        .confirmationDialog("우리 가족 그룹을 나갈까요?", isPresented: $isLeavingGroup, titleVisibility: .visible) {
            Button("그룹 나가기", role: .destructive, action: dismiss.callAsFunction)
            Button("취소", role: .cancel) { }
        } message: {
            Text("나가면 그룹의 일정과 멤버 정보를 더 이상 볼 수 없어요.")
        }
    }
}

#Preview("그룹 상세") {
    GroupDetailView()
}
