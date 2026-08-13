import SwiftUI

struct GroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var eventStore: MoilEventStore
    @EnvironmentObject private var sessionStore: MoilSessionStore

    @State private var members: [MoilRemoteMember] = []
    @State private var monthEvents: [CalendarEvent] = []
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
        VStack(spacing: 0) {
            // 다른 하위 페이지와 같은 공통 헤더를 씁니다.
            MoilInlineHeader(title: groupName, onBack: dismiss.callAsFunction)
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("구성원")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                if isLoading && members.isEmpty {
                    // 불러오는 동안에는 빈 자리만 두고 껍데기 UI는 그리지 않습니다.
                    Color.clear.frame(height: 0)
                } else if members.isEmpty {
                    Text("구성원 정보를 불러오지 못했어요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .background(MoilColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    memberList
                }

                Text("이번 달 일정")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 15)
                    .padding(.bottom, 10)

                monthEventList

                Spacer(minLength: 24)
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .padding(.bottom, 24)
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MoilColor.background.ignoresSafeArea())
        // 그룹 나가기는 화면 맨 아래에 둡니다.
        .safeAreaInset(edge: .bottom) {
            MoilButton(title: "그룹 나가기") { isLeavingGroup = true }
                .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                .padding(.bottom, 12)
        }
        .task(id: groupID) {
            await loadDetail()
        }
        .alert("\(groupName) 그룹을 나갈까요?", isPresented: $isLeavingGroup) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                Task { await leaveGroup() }
            }
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

    /// 이번 달에 어떤 일정이 있는지 목록으로 보여 줍니다.
    private var monthEventList: some View {
        VStack(spacing: 0) {
            if monthEvents.isEmpty {
                Text("\(monthLabel)에 등록된 일정이 없어요")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            } else {
                ForEach(monthEvents) { event in
                    HStack(spacing: 12) {
                        Circle().fill(event.color).frame(width: 8, height: 8)
                        Text(event.title)
                            .font(MoilTypography.semibold(15))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(eventDateText(event))
                            .font(MoilTypography.regular(13))
                            .foregroundStyle(MoilColor.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)

                    if event.id != monthEvents.last?.id {
                        Divider()
                            .overlay(MoilColor.emptyStateBorder)
                            .padding(.leading, 34)
                    }
                }
            }
        }
        .foregroundStyle(MoilColor.textPrimary)
        .background(MoilColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func eventDateText(_ event: CalendarEvent) -> String {
        guard let time = event.startTime else { return "\(event.day)일" }
        return "\(event.day)일 \(time)"
    }

    private var memberList: some View {
        VStack(spacing: 0) {
            ForEach(members.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    MoilAvatar(color: MoilAvatarColor.color(for: members[index].colorId), size: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(members[index].displayName).font(MoilTypography.semibold(15))
                        Text(roleTitle(members[index].role))
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 64)

                if index < members.count - 1 {
                    Divider()
                        .overlay(MoilColor.emptyStateBorder)
                        .padding(.leading, 60)
                }
            }
        }
        .foregroundStyle(MoilColor.textPrimary)
        .background(MoilColor.surface)
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
            monthEvents = loadedEvents(groupID)
        } catch {
            members = groupStore.members(for: groupID)
            monthEvents = loadedEvents(groupID)
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadedEvents(_ groupID: String) -> [CalendarEvent] {
        eventStore.events(groupId: groupID, month: monthRequest)
            .compactMap(CalendarEvent.init(remote:))
            .sorted { ($0.day, $0.startTime ?? "") < ($1.day, $1.startTime ?? "") }
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
