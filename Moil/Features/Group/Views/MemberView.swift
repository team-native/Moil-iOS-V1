import SwiftUI

struct MemberView: View {
    @State private var selectedGroup = "우리 가족"
    @State private var notificationsEnabled = true
    @State private var copied = false
    @State private var isAdministratorMode = false
    @State private var isEditingGroupName = false

    private let members: [(String, String, Color)] = [
        ("아빠", "관리자", .blue), ("엄마", "멤버", .red), ("나", "멤버", .green), ("동생", "멤버", .orange)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("멤버").font(MoilTypography.bold(26))
                    Text(selectedGroup).font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(["우리 가족", "대학 동기", "회사 팀"], id: \.self) { group in
                            Button(group) { selectedGroup = group }
                                .font(MoilTypography.semibold(13))
                                .foregroundStyle(selectedGroup == group ? .white : MoilColor.textSecondary)
                                .padding(.horizontal, 14).frame(height: 34)
                                .background(selectedGroup == group ? MoilColor.primary : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 6)

                    Toggle("관리자 권한으로 보기", isOn: $isAdministratorMode)
                        .font(MoilTypography.regular(13))
                        .tint(MoilColor.primary)

                    SectionTitle("구성원")
                    VStack(spacing: 0) {
                        ForEach(members.indices, id: \.self) { index in
                            MemberRow(member: members[index])
                            if index < members.count - 1 { Divider().padding(.leading, 64) }
                        }
                    }
                    .padding(.vertical, 4).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("초대 코드").font(MoilTypography.semibold(13))
                        HStack {
                            Text("FAM-7X2Q").font(MoilTypography.bold(19)).tracking(1)
                            Spacer()
                            Button(copied ? "복사됨" : "복사") { copied = true }
                                .font(MoilTypography.bold(12)).foregroundStyle(.white)
                                .padding(.horizontal, 12).frame(height: 34)
                                .background(MoilColor.primary).clipShape(Capsule())
                        }
                    }
                    .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))

                    SectionTitle("그룹 설정")
                    VStack(spacing: 0) {
                        Toggle("알림 받기", isOn: $notificationsEnabled).padding(14).tint(MoilColor.primary)
                        Divider()
                        Button("그룹 나가기") { }
                            .font(MoilTypography.regular(15)).foregroundStyle(MoilColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    }
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))

                    if isAdministratorMode {
                        VStack(spacing: 0) {
                            AdminSettingRow(title: "그룹 이름 변경") { isEditingGroupName = true }
                            Divider()
                            AdminSettingRow(title: "멤버 권한 설정")
                            Divider()
                            AdminSettingRow(title: "소셜미디어로 초대 링크 공유")
                        }
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(16).padding(.top, 8)
            }
            .background(MoilColor.background)
            .alert("그룹 이름 변경", isPresented: $isEditingGroupName) {
                TextField("그룹 이름", text: $selectedGroup)
                Button("취소", role: .cancel) { }
                Button("저장") { }
            } message: {
                Text("새로운 그룹 이름을 입력해주세요")
            }
        }
    }
}

private struct AdminSettingRow: View {
    let title: String
    var action: () -> Void = { }
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(MoilTypography.regular(15)).foregroundStyle(MoilColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(MoilColor.textTertiary)
            }
            .padding(14)
        }
    }
}

private struct SectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title).font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary) }
}

private struct MemberRow: View {
    let member: (String, String, Color)
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(member.2).frame(width: 38, height: 38).overlay { Image(systemName: "person.fill").foregroundStyle(.white) }
            VStack(alignment: .leading, spacing: 3) {
                Text(member.0).font(MoilTypography.semibold(15))
                Text(member.1).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary)
            }
            Spacer()
            Circle().fill(member.2).frame(width: 8, height: 8)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}
