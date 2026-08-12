import SwiftUI

struct GroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var eventStore: MoilEventStore
    @EnvironmentObject private var sessionStore: MoilSessionStore

    @State private var members: [MoilRemoteMember] = []
    @State private var monthEventCount = 0
    @State private var isLoading = true
    @State private var isLeavingGroup = false
    @State private var errorMessage: String?

    var onLeave: () -> Void = { }

    private var group: MoilGroup? { groupStore.selectedGroup }
    private var groupID: String? { group?.id }
    private var groupName: String { group?.name ?? "그룹" }
    private var monthRequest: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: .now)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: .now)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 9, height: 16)
                    }
                    Text(groupName)
                        .font(MoilTypography.bold(22))
                }
                .foregroundStyle(MoilColor.groupDetailTextPrimary)
                .safeAreaPadding(.top, 22)

                Text("구성원")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .padding(.top, 17)
                    .padding(.bottom, 10)

                if isLoading && members.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .background(MoilColor.groupDetailSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else if members.isEmpty {
                    Text("구성원 정보를 불러오지 못했어요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.groupDetailTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .background(MoilColor.groupDetailSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    memberList
                }

                Text("이번 달 일정")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .padding(.top, 15)
                    .padding(.bottom, 10)

                Text("\(monthLabel) 일정 \(monthEventCount)건")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MoilColor.groupDetailSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                MoilButton(title: "그룹 나가기") { isLeavingGroup = true }
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .padding(.bottom, 32)
        }
        .background(MoilColor.groupDetailBackground.ignoresSafeArea())
        .task(id: groupID) {
            await loadDetail()
        }
        .confirmationDialog("\(groupName) 그룹을 나갈까요?", isPresented: $isLeavingGroup, titleVisibility: .visible) {
            Button("그룹 나가기", role: .destructive) {
                Task { await leaveGroup() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("나가면 그룹의 일정과 멤버 정보를 더 이상 볼 수 없어요.")
        }
        .alert("그룹 처리 오류", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했어요.")
        }
    }

    private var memberList: some View {
        VStack(spacing: 0) {
            ForEach(members.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    MoilAvatar(color: MoilAvatarColor.color(for: members[index].colorId), size: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(members[index].nickname).font(MoilTypography.semibold(15))
                        Text(roleTitle(members[index].role))
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 64)

                if index < members.count - 1 {
                    Divider()
                        .overlay(MoilColor.groupDetailSeparator)
                        .padding(.leading, 60)
                }
            }
        }
        .foregroundStyle(MoilColor.groupDetailTextPrimary)
        .background(MoilColor.groupDetailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func loadDetail() async {
        guard let groupID else {
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let service = sessionStore.service()
            try await groupStore.refreshDetail(id: groupID, using: service)
            members = try await groupStore.loadMembers(groupId: groupID, using: service)
            try await eventStore.load(groupId: groupID, month: monthRequest, using: service)
            monthEventCount = eventStore.events(groupId: groupID, month: monthRequest).count
        } catch {
            members = groupStore.members(for: groupID)
            monthEventCount = eventStore.events(groupId: groupID, month: monthRequest).count
            errorMessage = error.localizedDescription
        }
    }

    private func leaveGroup() async {
        guard let groupID else { return }
        do {
            try await sessionStore.service().leaveGroup(groupId: groupID)
            groupStore.removeGroup(groupID)
            eventStore.invalidate(groupId: groupID)
            onLeave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func roleTitle(_ role: String) -> String {
        switch role.uppercased() {
        case "OWNER", "ADMIN": "관리자"
        default: "멤버"
        }
    }
}

#Preview("그룹 상세") {
    GroupDetailView()
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilEventStore())
        .environmentObject(MoilSessionStore())
}
