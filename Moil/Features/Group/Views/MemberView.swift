import SwiftUI

struct MemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroup = "우리 가족"
    @State private var notificationsEnabled = true
    @State private var copied = false
    @State private var isAdministratorMode = false
    @State private var isEditingGroupName = false
    @State private var isEditingPermissions = false
    @State private var isSharingInvite = false
    @State private var isTransferringAdmin = false
    @State private var isLeavingGroup = false
    @State private var feedbackMessage: String?
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var isMyPagePresented = false

    private let members: [(String, String, Color)] = [
        ("아빠", "관리자", MoilAvatarColor.blue), ("엄마", "멤버", MoilAvatarColor.red), ("나", "멤버", MoilAvatarColor.green), ("동생", "멤버", MoilAvatarColor.orange)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("멤버")
                        .font(MoilTypography.bold(26))
                        .padding(.bottom, 4)
                    Text(selectedGroup)
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                        .padding(.bottom, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                        ForEach(["우리 가족", "대학 동기", "회사 팀"], id: \.self) { group in
                            Button(group) { selectedGroup = group }
                                .font(MoilTypography.semibold(13))
                                .foregroundStyle(selectedGroup == group ? .white : MoilColor.textSecondary)
                                .padding(.horizontal, 14).frame(height: 34)
                                .background(selectedGroup == group ? MoilColor.primary : MoilColor.background)
                                .clipShape(Capsule())
                        }
                    }
                    }
                    .padding(.bottom, 28)

                    SectionTitle("구성원")
                        .padding(.bottom, 8)
                    VStack(spacing: 0) {
                        ForEach(members.indices, id: \.self) { index in
                            MemberRow(member: members[index])
                            if index < members.count - 1 { Divider().padding(.leading, 64) }
                        }
                    }
                    .padding(.vertical, 4).background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, 24)

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
                    .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, 24)

                    SectionTitle("그룹 설정")
                        .padding(.bottom, 8)
                    VStack(spacing: 0) {
                        Toggle("알림 받기", isOn: $notificationsEnabled).padding(14).tint(MoilColor.primary)
                        Divider()
                        Button("그룹 나가기") { isLeavingGroup = true }
                            .font(MoilTypography.regular(15)).foregroundStyle(MoilColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    }
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 20))

                    if isAdministratorMode {
                        SectionTitle("관리자 설정")
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                        VStack(spacing: 0) {
                            AdminSettingRow(title: "그룹 이름 변경") { isEditingGroupName = true }
                            Divider()
                            AdminSettingRow(title: "멤버 권한 설정") { isEditingPermissions = true }
                            Divider()
                            AdminSettingRow(title: "소셜미디어로 초대 링크 공유") { isSharingInvite = true }
                            Divider()
                            AdminSettingRow(title: "관리자 권한 이전") { isTransferringAdmin = true }
                        }
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 16)
                .safeAreaPadding(.top, 6)
                .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            MoilTabBar(selected: .members) { tab in
                switch tab {
                case .calendar:
                    dismiss()
                case .members:
                    break
                case .create:
                    isJoinGroupPresented = true
                case .profile:
                    isMyPagePresented = true
                }
            }
        }
        .background(MoilColor.background)
        .alert("그룹 이름 변경", isPresented: $isEditingGroupName) {
                TextField("그룹 이름", text: $selectedGroup)
                Button("취소", role: .cancel) { }
                Button("저장") { feedbackMessage = "그룹 이름을 변경했어요." }
            } message: {
                Text("새로운 그룹 이름을 입력해주세요")
            }
            .sheet(isPresented: $isEditingPermissions) {
                PermissionEditorView()
                    .presentationDetents([.height(327)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isSharingInvite) {
                InviteShareView()
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("관리자 권한 이전", isPresented: $isTransferringAdmin, titleVisibility: .visible) {
                Button("지민에게 이전") { feedbackMessage = "지민에게 관리자 권한을 이전했어요." }
                Button("서연에게 이전") { feedbackMessage = "서연에게 관리자 권한을 이전했어요." }
                Button("취소", role: .cancel) { }
            } message: {
                Text("새 관리자를 선택하면 현재 관리자 권한이 변경됩니다.")
            }
            .confirmationDialog("그룹을 나갈까요?", isPresented: $isLeavingGroup, titleVisibility: .visible) {
                Button("그룹 나가기", role: .destructive) { feedbackMessage = "\(selectedGroup) 그룹에서 나왔어요." }
                Button("취소", role: .cancel) { }
            } message: {
                Text("나가면 그룹의 일정과 멤버 정보를 더 이상 볼 수 없어요.")
            }
            .alert("알림", isPresented: Binding(get: { feedbackMessage != nil }, set: { if !$0 { feedbackMessage = nil } })) {
                Button("확인", role: .cancel) { feedbackMessage = nil }
            } message: {
                Text(feedbackMessage ?? "")
            }
            .fullScreenCover(isPresented: $isJoinGroupPresented) {
                GroupJoinCodeView {
                    isJoinGroupPresented = false
                    isJoinProfilePresented = true
                }
            }
            .fullScreenCover(isPresented: $isJoinProfilePresented) {
                GroupJoinProfileView { isJoinProfilePresented = false }
            }
            .fullScreenCover(isPresented: $isMyPagePresented) {
                MyPageView()
            }
    }
}

#Preview("멤버 관리") {
    MemberView()
}

private struct InviteShareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    var body: some View {
        VStack(spacing: 20) {
            Text("초대 링크 공유").font(MoilTypography.bold(18)).padding(.top, 12)
            Text("친구에게 링크를 보내 그룹에 초대하세요")
                .font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
            HStack(spacing: 24) {
                ForEach([("메시지", "message.fill"), ("카카오톡", "bubble.left.and.bubble.right.fill"), ("링크 복사", "doc.on.doc")], id: \.0) { item in
                    Button { copied = item.0 == "링크 복사" } label: {
                        VStack(spacing: 8) {
                            Circle().fill(MoilColor.primary.opacity(0.12)).frame(width: 52, height: 52)
                                .overlay { Image(systemName: item.1).foregroundStyle(MoilColor.primary) }
                            Text(item.0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textPrimary)
                        }
                    }
                }
            }
            Text(copied ? "초대 링크를 복사했습니다" : "")
                .font(MoilTypography.regular(12)).foregroundStyle(MoilColor.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity).background(.white)
    }
}

private struct PermissionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var administrator: Set<String> = ["나"]
    private let rows: [(String, Color)] = [("나", MoilAvatarColor.green), ("지민", MoilAvatarColor.purple), ("서연", MoilAvatarColor.pink)]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("멤버 권한 설정").font(MoilTypography.bold(17)).padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)
            ForEach(rows, id: \.0) { row in
                HStack(spacing: 10) {
                    MoilAvatar(color: row.1, size: 30)
                    Text(row.0).font(MoilTypography.semibold(14))
                    Spacer()
                    Picker("권한", selection: Binding(get: { administrator.contains(row.0) }, set: { enabled in
                        if enabled {
                            administrator.insert(row.0)
                        } else {
                            administrator.remove(row.0)
                        }
                    })) {
                        Text("멤버").tag(false)
                        Text("관리자").tag(true)
                    }
                    .pickerStyle(.segmented).frame(width: 132)
                }
                .padding(.horizontal, 20).frame(height: 52)
                if row.0 != "서연" { Divider().padding(.horizontal, 20) }
            }
            Button("완료", action: dismiss.callAsFunction)
                .font(MoilTypography.bold(14)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(20)
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
            MoilAvatar(color: member.2, size: 38)
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
