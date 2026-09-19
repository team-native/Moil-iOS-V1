import SwiftUI

struct ContentView: View {
    @StateObject private var sessionStore = MoilWatchSessionStore()

    @State private var groupName = ""
    @State private var resolvedGroupId: String?
    @State private var members: [FamilyMember] = []
    @State private var remoteEvents: [MoilRemoteEvent] = []
    @State private var selectedItem: ScheduleItem?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let calendar = Calendar.current

    var body: some View {
        // 자식 뷰들이 WatchColor.xxx를 읽기 전에, 이번 렌더링에서 쓸 다크/라이트 값을
        // 먼저 맞춰 둡니다. watchOS는 Assets.xcassets의 다크 모드 색상을 자동으로
        // 전환해 주지 않아(WatchColor.swift 참고) 코드에서 직접 전달해야 합니다.
        WatchColor.isDarkMode = sessionStore.isDarkMode
        return Group {
            if !sessionStore.isAuthenticated {
                waitingForPhoneView
            } else {
                mainTabs
            }
        }
        .task(id: "\(sessionStore.accessToken ?? "")-\(sessionStore.groupId ?? "")") {
            await load()
        }
    }

    private var waitingForPhoneView: some View {
        VStack(spacing: 8) {
            moilMascot(size: 44)
            Text("아이폰의 Moil 앱에서\n로그인하면 자동으로 연결돼요")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchColor.background)
    }

    private func moilMascot(size: CGFloat, pulsing: Bool = false) -> some View {
        MoilMascotView(size: size, pulsing: pulsing)
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                MonthlyView(
                    legend: Array(members.prefix(3)),
                    colorForEvent: { owner(for: $0).color },
                    loadEvents: { await loadEvents(for: $0) }
                )
                .id(resolvedGroupId)
            }
            NavigationStack {
                FamilyView(members: members)
            }
            NavigationStack {
                Group {
                    if isLoading && remoteEvents.isEmpty && members.isEmpty {
                        moilMascot(size: 36, pulsing: true)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 11))
                            .foregroundStyle(WatchColor.textSecondary)
                            .padding()
                    } else {
                        TodayView(
                            groupName: groupName,
                            dateTitle: todayTitle,
                            items: todayItems,
                            onSelect: { selectedItem = $0 }
                        )
                    }
                }
                .background(WatchColor.background)
                .navigationDestination(item: $selectedItem) { item in
                    if let detail = eventDetail(for: item) {
                        ScheduleDetailView(event: detail)
                    }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private func load() async {
        guard sessionStore.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let service = sessionStore.service()
            let groups = try await service.groups()
            let targetId = sessionStore.groupId ?? groups.first?.id
            guard let targetId, let group = groups.first(where: { $0.id == targetId }) ?? groups.first else {
                errorMessage = "참여 중인 그룹이 없어요."
                return
            }
            groupName = group.name
            resolvedGroupId = group.id
            async let membersTask = service.members(groupId: group.id)
            async let eventsTask = service.events(groupId: group.id, month: monthRequestValue)
            let (remoteMembers, events) = try await (membersTask, eventsTask)
            members = remoteMembers.map(FamilyMember.init(remote:))
            remoteEvents = events
            errorMessage = nil
        } catch {
            guard !error.isRequestCancellation else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Today

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: Date())
    }

    private func owner(for event: MoilRemoteEvent) -> FamilyMember {
        members.first { $0.id == event.members.first?.id }
            ?? FamilyMember(
                id: event.id,
                initial: String((event.ownerName ?? "?").prefix(1)),
                name: event.ownerName ?? "",
                color: MemberColorPalette.color(for: event.colorId)
            )
    }

    private var todayItems: [ScheduleItem] {
        remoteEvents
            .filter { $0.date == todayDateString }
            .sorted { ($0.startTime ?? "") < ($1.startTime ?? "") }
            .map { event in
                ScheduleItem(
                    id: event.id,
                    time: event.isAllDay ? "종일" : (event.startTime ?? "-"),
                    title: event.title,
                    owner: owner(for: event)
                )
            }
    }

    private func eventDetail(for item: ScheduleItem) -> EventDetail? {
        guard let event = remoteEvents.first(where: { $0.id == item.id }) else { return nil }
        let attendees = event.members.compactMap { eventMember in
            members.first { $0.id == eventMember.id }
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateTitleFormatter = DateFormatter()
        dateTitleFormatter.locale = Locale(identifier: "ko_KR")
        dateTitleFormatter.dateFormat = "M월 d일 · EEEE"
        let dateLabel = formatter.date(from: event.date).map { dateTitleFormatter.string(from: $0) } ?? event.date
        let timeLocationParts = [
            event.isAllDay ? "종일" : (event.startTime ?? ""),
            event.location,
        ].compactMap { $0?.isEmpty == false ? $0 : nil }

        return EventDetail(
            id: event.id,
            owner: owner(for: event),
            title: event.title,
            dateLabel: dateLabel,
            timeLocationLabel: timeLocationParts.joined(separator: " · "),
            attendeeCountLabel: "가족 \(event.members.count)명",
            attendees: attendees,
            attendingSummary: "\(attendees.count)명 참석"
        )
    }

    // MARK: - Monthly

    private var monthRequestValue: String {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    /// 연속 스크롤 달력이 화면에 걸린 달을 하나씩 불러올 때 사용합니다.
    private func loadEvents(for month: Date) async -> [MoilRemoteEvent] {
        guard let resolvedGroupId else { return [] }
        let components = calendar.dateComponents([.year, .month], from: month)
        let monthValue = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
        do {
            return try await sessionStore.service().events(groupId: resolvedGroupId, month: monthValue)
        } catch {
            return []
        }
    }
}

/// 로딩/연결 대기 화면에서 공통으로 쓰는 Moil 마스코트입니다. 시스템 스피너나 기본
/// SF Symbol 대신 브랜드 로고를 보여줘 워치 로딩 화면이 기본 아이콘처럼 보이지 않게 합니다.
private struct MoilMascotView: View {
    let size: CGFloat
    var pulsing = false

    @State private var isPulsing = false

    var body: some View {
        Image("MoilMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .opacity(pulsing && isPulsing ? 0.55 : 1)
            .onAppear {
                guard pulsing else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

#Preview {
    ContentView()
}
