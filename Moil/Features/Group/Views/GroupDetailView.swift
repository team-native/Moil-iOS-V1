import SwiftUI

struct GroupDetailView: View {
    private let members: [(String, String, Color)] = [("아빠", "관리자", .blue), ("엄마", "멤버", .red), ("나", "멤버", .green), ("동생", "멤버", .orange)]
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) { Image(systemName: "chevron.left"); Text("우리 가족").font(MoilTypography.bold(22)) }.padding(.top, 20)
            Text("구성원").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary)
            VStack(spacing: 0) { ForEach(members.indices, id: \.self) { index in HStack(spacing: 12) { Circle().fill(members[index].2).frame(width: 34, height: 34).overlay { Image(systemName: "person.fill").font(.system(size: 12)).foregroundStyle(.white) }; VStack(alignment: .leading, spacing: 3) { Text(members[index].0).font(MoilTypography.semibold(15)); Text(members[index].1).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }; Spacer() }.padding(14); if index < members.count - 1 { Divider().padding(.leading, 60) } } }.background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            Text("이번 달 일정").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary)
            Text("7월 일정 5건").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary).frame(maxWidth: .infinity).padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            Button("그룹 나가기") { }.font(MoilTypography.semibold(15)).foregroundStyle(MoilColor.primary).frame(maxWidth: .infinity).padding(.vertical, 14)
        }.padding(16) }.background(MoilColor.background)
    }
}
