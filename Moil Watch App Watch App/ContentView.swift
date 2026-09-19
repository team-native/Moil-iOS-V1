import SwiftUI

struct ContentView: View {
    @StateObject private var sessionStore = MoilWatchSessionStore()

    @State private var groupName = ""
    @State private var members: [FamilyMember] = []
    @State private var remoteEvents: [MoilRemoteEvent] = []
    @State private var selectedItem: ScheduleItem?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let calendar = Calendar.current

    var body: some View {
        Group {
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
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 22))
                .foregroundStyle(WatchColor.textSecondary)
            Text("아이폰의 Moil 앱에서\n로그인하면 자동으로 연결돼요")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchColor.background)
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                Group {
                    if isLoading && remoteEvents.isEmpty && members.isEmpty {
                        ProgressView().tint(WatchColor.textSecondary)
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
            NavigationStack {
                FamilyView(members: members, availability: todayAvailability)
            }
            NavigationStack {
                MonthlyView(
                    monthTitle: monthTitle,
                    yearTitle: yearTitle,
                    weekdaySymbols: ["일", "월", "화", "수", "목", "금", "토"],
                    weeks: monthWeeks,
                    legend: Array(members.prefix(3))
                )
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

    // MARK: - Family availability (오늘 일정 사이 빈 시간을 간단히 계산합니다)

    private var todayAvailability: [AvailabilitySlot] {
        let dayStart = 9 * 60
        let dayEnd = 21 * 60
        let busyRanges: [(Int, Int)] = todayItems.compactMap { item in
            guard let minutes = minutes(from: item.time) else { return nil }
            return (minutes, minutes + 60)
        }.sorted { $0.0 < $1.0 }

        var slots: [AvailabilitySlot] = []
        var cursor = dayStart
        for range in busyRanges {
            if range.0 - cursor >= 30 {
                slots.append(makeSlot(start: cursor, end: range.0))
            }
            cursor = max(cursor, range.1)
        }
        if dayEnd - cursor >= 30 {
            slots.append(makeSlot(start: cursor, end: dayEnd, isOpenEnded: true))
        }
        return Array(slots.prefix(3))
    }

    private func minutes(from time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return hour * 60 + minute
    }

    private func makeSlot(start: Int, end: Int, isOpenEnded: Bool = false) -> AvailabilitySlot {
        let range = isOpenEnded ? "\(timeString(start)) 이후" : "\(timeString(start))–\(timeString(end))"
        return AvailabilitySlot(
            id: "\(start)-\(end)",
            timeRange: range,
            summary: "\(members.count)명 모두",
            indicatorColor: members.first?.color ?? WatchColor.textSecondary
        )
    }

    private func timeString(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    // MARK: - Monthly

    private var monthRequestValue: String {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: Date())
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    private var monthWeeks: [[MonthDay]] {
        let today = Date()
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: today),
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlankDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let todayDay = calendar.component(.day, from: today)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var colorByDay: [Int: Color] = [:]
        for event in remoteEvents {
            guard let date = dateFormatter.date(from: event.date),
                  calendar.isDate(date, equalTo: today, toGranularity: .month) else { continue }
            let day = calendar.component(.day, from: date)
            colorByDay[day] = owner(for: event).color
        }

        var cells: [MonthDay] = (0..<leadingBlankDays).map { MonthDay(id: -($0 + 1), day: nil, isToday: false, eventColor: nil) }
        cells += (1...daysInMonth).map { day in
            MonthDay(id: day, day: day, isToday: day == todayDay, eventColor: colorByDay[day])
        }
        while cells.count % 7 != 0 {
            cells.append(MonthDay(id: -(1000 + cells.count), day: nil, isToday: false, eventColor: nil))
        }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }
}

#Preview {
    ContentView()
}
