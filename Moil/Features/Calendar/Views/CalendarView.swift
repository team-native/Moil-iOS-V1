import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @EnvironmentObject private var eventStore: MoilEventStore
    var onTabSelect: ((MoilTab) -> Void)? = nil
    var onCreateGroup: (() -> Void)? = nil
    var showsTabBar = true
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let calendar = Calendar.current
    @State private var isGroupMenuPresented = false
    @State private var isScheduleComposerPresented = false
    @State private var isDaySchedulePresented = false
    @State private var isScheduleSearchPresented = false
    @State private var scheduleDraftDay = 22
    @State private var isMemberViewPresented = false
    @State private var isMyPagePresented = false
    @State private var isCreateGroupPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var isEmptyCalendarPresented = false
    @State private var shouldOpenCreateGroupAfterProfile = false
    @State private var displayedMonth = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var serverError: String?

    /// 날짜 칸마다 전체 목록을 다시 변환하지 않도록 한 번만 묶어 둡니다.
    @MainActor
    private var eventsByDay: [Int: [CalendarEvent]] {
        let events = eventStore.events(groupId: groupStore.selectedGroupId, month: monthRequestValue)
            .compactMap(CalendarEvent.init(remote:))
        var result: [Int: [CalendarEvent]] = [:]
        for event in events {
            for date in event.dates(in: displayedMonth) {
                result[calendar.component(.day, from: date), default: []].append(event)
            }
        }
        return result
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var leadingBlankDays: Int {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let firstDay = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 1)) ?? displayedMonth
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    /// 선택한 달이 실제로 차지하는 주 수만 표시합니다. Figma의 2026년 7월은 다섯 줄입니다.
    private var calendarRowCount: Int {
        Int(ceil(Double(leadingBlankDays + daysInMonth) / 7.0))
    }

    private let dayCellHeight: CGFloat = 108
    @State private var selectedDay = Calendar.current.component(.day, from: Date())

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).locale(Locale(identifier: "ko_KR")))
    }

    private var yearTitle: String {
        displayedMonth.formatted(.dateTime.year().locale(Locale(identifier: "ko_KR")))
    }

    var body: some View {
        ZStack {
            MoilColor.background
            if groupStore.groups.isEmpty {
                EmptyCalendarView(
                    onJoin: {
                        if let onTabSelect { onTabSelect(.create) }
                        else { isJoinGroupPresented = true }
                    },
                    onCreate: {
                        if let onCreateGroup { onCreateGroup() }
                        else { isCreateGroupPresented = true }
                    }
                )
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isGroupMenuPresented.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                HStack(spacing: -7) {
                                    ForEach(groupStore.members(for: groupStore.selectedGroupId).prefix(4)) { member in
                                        MoilAvatar(color: MoilAvatarColor.color(for: member.colorId), size: 24)
                                            .overlay { Circle().stroke(MoilColor.background, lineWidth: 2) }
                                    }
                                }
                                Text(groupStore.selectedGroupName)
                                    .font(MoilTypography.semibold(15))
                                    .foregroundStyle(MoilColor.textPrimary)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                        Spacer()
                        Button { isScheduleSearchPresented = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(MoilColor.textPrimary)
                        }
                    }
                    .frame(height: 32)
                    .overlay(alignment: .topLeading) {
                        if isGroupMenuPresented {
                            VStack(spacing: 0) {
                                ForEach(groupStore.groups) { group in
                                    Button {
                                        groupStore.selectGroup(group.id)
                                        isGroupMenuPresented = false
                                    } label: {
                                        HStack(spacing: 10) {
                                            Circle().fill(group.color).frame(width: 8, height: 8)
                                            Text(group.name).font(MoilTypography.semibold(14))
                                            Spacer()
                                        }
                                        .padding(.horizontal, 14)
                                        .frame(height: 46)
                                    }
                                    .foregroundStyle(MoilColor.textPrimary)
                                    if group.id != groupStore.groups.last?.id { Divider() }
                                }
                            }
                            .frame(width: 193)
                            .background(MoilColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                            .offset(y: 42)
                        }
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                    .safeAreaPadding(.top, MoilTabScreenMetrics.topPadding)
                    .zIndex(1)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(monthTitle).font(MoilTypography.heavy(32))
                            Text(yearTitle).font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
                        }
                        Spacer()
                        Button { moveMonth(by: -1) } label: {
                            Image(systemName: "chevron.left")
                            .frame(width: 30, height: 30)
                            .background(MoilColor.surface)
                            .clipShape(Circle())
                        }
                        .foregroundStyle(MoilColor.textPrimary)
                        Button { moveMonth(by: 1) } label: {
                            Image(systemName: "chevron.right")
                            .frame(width: 30, height: 30)
                            .background(MoilColor.surface)
                            .clipShape(Circle())
                        }
                        .foregroundStyle(MoilColor.textPrimary)
                        .padding(.leading, 6)
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                    .padding(.vertical, 16)
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(["일","월","화","수","목","금","토"], id: \.self) {
                            Text($0)
                                .font(MoilTypography.semibold(12))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                    .padding(.bottom, 9)
                    ScrollView(showsIndicators: false) {
                        let dayEvents = eventsByDay
                        LazyVGrid(columns: columns, spacing: 9) {
                            ForEach(0..<(calendarRowCount * 7), id: \.self) { slot in
                                calendarSlot(slot, events: dayEvents)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                }
            }
        }
        .moilTabScreenLayout(selected: .calendar, isTabBarVisible: showsTabBar) { tab in
            if let onTabSelect {
                onTabSelect(tab)
            } else {
                switch tab {
                case .calendar: break
                case .members: isMemberViewPresented = true
                case .create: isJoinGroupPresented = true
                case .profile: isMyPagePresented = true
                }
            }
        }
        .sheet(isPresented: $isScheduleComposerPresented) {
            ScheduleComposerView(
                initialDate: scheduleDraftDate,
                members: groupStore.members(for: groupStore.selectedGroupId)
            ) { startDate, endDate, title, isAllDay, startTime, endTime, location, memo, memberIDs in
                createEvent(
                    startDate: startDate,
                    endDate: endDate,
                    title: title,
                    isAllDay: isAllDay,
                    startTime: startTime,
                    endTime: endTime,
                    location: location,
                    memo: memo,
                    sharedMemberIDs: memberIDs
                )
            }
                .presentationDetents([.height(565)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isDaySchedulePresented) {
            DayScheduleSheet(
                day: scheduleDraftDay,
                dateTitle: scheduleDraftDateTitle,
                events: eventsByDay[scheduleDraftDay] ?? [],
                onAdd: {
                    isDaySchedulePresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isScheduleComposerPresented = true
                    }
                },
                onSelect: { event in
                    isDaySchedulePresented = false
                    Task { await selectEvent(event) }
                }
            )
            .presentationDetents([.height(470)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedEvent) { event in
            EventEditorView(event: event) { title in
                updateEvent(event, title: title)
            } onDelete: {
                deleteEvent(event)
            }
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isMemberViewPresented) { MemberView(showsTabBar: false) }
        .fullScreenCover(isPresented: $isMyPagePresented, onDismiss: {
            guard shouldOpenCreateGroupAfterProfile else { return }
            shouldOpenCreateGroupAfterProfile = false
            isCreateGroupPresented = true
        }) {
            MyPageView(
                onCreateGroup: {
                    shouldOpenCreateGroupAfterProfile = true
                    isMyPagePresented = false
                },
                onLeaveGroup: {
                    isMyPagePresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isEmptyCalendarPresented = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $isCreateGroupPresented) { CreateGroupView() }
        .fullScreenCover(isPresented: $isJoinGroupPresented) {
            GroupJoinCodeView(onNext: {
                isJoinGroupPresented = false
                isJoinProfilePresented = true
            }, showsTabBar: false)
        }
        .fullScreenCover(isPresented: $isJoinProfilePresented) {
            GroupJoinProfileView { isJoinProfilePresented = false }
        }
        .fullScreenCover(isPresented: $isEmptyCalendarPresented) {
            EmptyCalendarView(
                onJoin: {
                    isEmptyCalendarPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isJoinGroupPresented = true
                    }
                },
                onCreate: {
                    isEmptyCalendarPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isCreateGroupPresented = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $isScheduleSearchPresented) {
            ScheduleSearchView(
                groupId: groupStore.selectedGroupId,
                month: monthRequestValue
            )
        }
        .alert("서버 오류", isPresented: Binding(get: { serverError != nil }, set: { if !$0 { serverError = nil } })) {
            Button("확인", role: .cancel) { serverError = nil }
        } message: {
            Text(serverError ?? "")
        }
        .task(id: "\(groupStore.selectedGroupId ?? "")-\(monthRequestValue)") {
            await loadMemberProfiles()
            await loadEvents()
        }
    }

    private func loadMemberProfiles() async {
        guard let groupId = groupStore.selectedGroupId else { return }
        do {
            _ = try await groupStore.loadMembers(groupId: groupId, using: sessionStore.service())
        } catch {
            guard !error.isRequestCancellation else { return }
            serverError = error.localizedDescription
        }
    }

    private func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        selectedDay = calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
            ? calendar.component(.day, from: Date())
            : 0
    }

    private var monthRequestValue: String {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private var scheduleDraftDateTitle: String {
        let components = calendar.dateComponents([.month], from: displayedMonth)
        return "\(components.month ?? 1)월 \(scheduleDraftDay)일"
    }

    private var scheduleDraftDate: Date {
        calendar.date(bySetting: .day, value: scheduleDraftDay, of: firstDayOfDisplayedMonth) ?? firstDayOfDisplayedMonth
    }

    private func loadEvents() async {
        guard let groupId = groupStore.selectedGroupId else { return }
        do {
            try await eventStore.load(groupId: groupId, month: monthRequestValue, using: sessionStore.service())
        } catch {
            guard !error.isRequestCancellation else { return }
            serverError = error.localizedDescription
        }
    }

    private func createEvent(
        startDate: Date,
        endDate: Date,
        title: String,
        isAllDay: Bool,
        startTime: String?,
        endTime: String?,
        location: String?,
        memo: String?,
        sharedMemberIDs: [String]
    ) {
        guard let groupId = groupStore.selectedGroupId, let groupID = Int(groupId) else {
            serverError = "그룹 정보를 불러오지 못했어요."
            return
        }
        let memberIDs = sharedMemberIDs.compactMap(Int.init)
        guard !memberIDs.isEmpty else {
            serverError = "일정을 공유할 구성원을 1명 이상 선택해주세요."
            return
        }
        let startDay = MoilCalendarDate.string(from: startDate)
        let selectedEndDay = MoilCalendarDate.string(from: max(endDate, startDate))
        let requestStartDate = "\(startDay) \(isAllDay ? "00:00" : startTime ?? "09:00")"
        let requestEndDate: String
        if isAllDay {
            guard let nextDate = MoilCalendarDate.nextDayString(from: selectedEndDay) else {
                serverError = "일정 종료 날짜를 만들지 못했어요."
                return
            }
            requestEndDate = "\(nextDate) 00:00"
        } else {
            requestEndDate = "\(selectedEndDay) \(endTime ?? "10:00")"
        }
        Task {
            do {
                _ = try await sessionStore.service().createEvent(CreateEventRequest(
                    groupId: groupID,
                    title: title,
                    startDate: requestStartDate,
                    endDate: requestEndDate,
                    location: location,
                    memo: memo,
                    sharedMemberIds: memberIDs
                ))
                await loadEvents()
            } catch { serverError = error.localizedDescription }
        }
    }

    private func updateEvent(_ event: CalendarEvent, title: String) {
        guard let groupId = groupStore.selectedGroupId else { return }
        let currentUserIDs = groupStore.members(for: groupId).filter(\.isMe).compactMap { Int($0.id) }
        let sharedMemberIDs = event.memberIDs.isEmpty ? currentUserIDs : event.memberIDs
        let startDate = "\(event.date) \(event.isAllDay ? "00:00" : event.startTime ?? "09:00")"
        let endDate = event.isAllDay
            ? "\(MoilCalendarDate.nextDayString(from: event.date) ?? event.date) 00:00"
            : "\(event.date) \(event.endTime ?? "10:00")"
        Task {
            do {
                let request = UpdateEventRequest(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    location: event.location,
                    memo: event.memo,
                    sharedMemberIds: sharedMemberIDs
                )
                try await sessionStore.service().updateEvent(id: event.id, request: request)
                await loadEvents()
            } catch { serverError = error.localizedDescription }
        }
    }

    private func deleteEvent(_ event: CalendarEvent) {
        Task {
            do {
                try await sessionStore.service().deleteEvent(id: event.id)
                await loadEvents()
            } catch { serverError = error.localizedDescription }
        }
    }

    private func selectEvent(_ event: CalendarEvent) async {
        do {
            let remoteEvent = try await sessionStore.service().event(id: event.id)
            selectedEvent = CalendarEvent(remote: remoteEvent) ?? event
        } catch {
            selectedEvent = event
        }
    }

    @ViewBuilder
    private func calendarSlot(_ slot: Int, events: [Int: [CalendarEvent]]) -> some View {
        let day = slot - leadingBlankDays + 1
        if (1...daysInMonth).contains(day) {
            calendarDay(day, events: events[day] ?? [])
        } else {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfDisplayedMonth) ?? displayedMonth
            Text("\(calendar.component(.day, from: date))")
                .font(MoilTypography.regular(16))
                .foregroundStyle(MoilColor.textPrimary.opacity(0.32))
                .frame(maxWidth: .infinity, minHeight: dayCellHeight, alignment: .top)
        }
    }

    private var firstDayOfDisplayedMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
    }

    private func calendarDay(_ day: Int, events: [CalendarEvent]) -> some View {
        Button {
            scheduleDraftDay = day
            selectedDay = day
            if events.isEmpty {
                isScheduleComposerPresented = true
            } else {
                isDaySchedulePresented = true
            }
        } label: {
            VStack(alignment: .center, spacing: 8) {
                Text("\(day)")
                    .font(MoilTypography.regular(15))
                    .foregroundStyle(selectedDay == day ? Color.white : MoilColor.textPrimary)
                    .frame(width: 32, height: 32, alignment: .center)
                    .background(selectedDay == day ? MoilColor.primary : .clear)
                    .clipShape(Circle())
                ForEach(events) { event in
                    eventChip(event, day: day)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: dayCellHeight, alignment: .top)
        }
        .buttonStyle(.plain)
    }

    private func eventChip(_ event: CalendarEvent, day: Int) -> some View {
        let currentDate = calendar.date(bySetting: .day, value: day, of: firstDayOfDisplayedMonth) ?? firstDayOfDisplayedMonth
        let weekday = calendar.component(.weekday, from: currentDate)
        // 기간 일정은 주를 넘길 때마다 새로운 한 줄의 일정 바로 시작합니다.
        let startsSegment = event.starts(on: currentDate) || weekday == calendar.firstWeekday
        let endsSegment = event.ends(on: currentDate) || weekday == 7
        return Text(startsSegment ? event.shortTitle : "")
            .font(MoilTypography.regular(10))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 4)
            // 단일·기간 일정 모두 같은 칩 규격을 사용해 여러 일정이 쌓여도 정렬이 유지됩니다.
            .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18, alignment: .leading)
            .background(event.color.opacity(0.45))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: startsSegment ? 4 : 0,
                    bottomLeadingRadius: startsSegment ? 4 : 0,
                    bottomTrailingRadius: endsSegment ? 4 : 0,
                    topTrailingRadius: endsSegment ? 4 : 0
                )
            )
    }

}

private struct CalendarEvent: Identifiable {
    /// 좁은 날짜 칸에서 말줄임표가 생기지 않도록 공백 포함 앞 여섯 글자만 씁니다.
    var shortTitle: String { String(title.prefix(6)) }

    let id: String
    let day: Int
    let owner: String
    let title: String
    let date: String
    let endDate: String
    let color: Color
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let memo: String?
    let memberIDs: [Int]

    init?(remote: MoilRemoteEvent) {
        guard let normalizedDate = MoilCalendarDate.normalizedString(from: remote.date),
              let eventDay = MoilCalendarDate.day(from: normalizedDate) else { return nil }
        id = remote.id
        day = eventDay
        owner = remote.ownerName ?? "나"
        title = remote.title
        date = normalizedDate
        let normalizedEnd = remote.endDate.flatMap(MoilCalendarDate.normalizedString(from:)) ?? normalizedDate
        // 종일 일정의 종료 자정은 API에서 다음 날로 저장되므로 화면에서는 전날까지 표시합니다.
        endDate = remote.isAllDay
            ? (MoilCalendarDate.previousDayString(from: normalizedEnd) ?? normalizedDate)
            : normalizedEnd
        color = MoilAvatarColor.color(for: remote.colorId)
        isAllDay = remote.isAllDay
        startTime = remote.startTime
        endTime = remote.endTime
        location = remote.location
        memo = remote.memo
        memberIDs = remote.members.compactMap { $0.id.flatMap(Int.init) }
    }

    func dates(in month: Date) -> [Date] {
        guard let start = MoilCalendarDate.date(from: date),
              let end = MoilCalendarDate.date(from: endDate) else { return [] }
        let first = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month)) ?? month
        guard let last = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: first) else { return [] }
        let visibleStart = max(start, first)
        let visibleEnd = min(max(end, start), last)
        guard visibleStart <= visibleEnd else { return [] }
        return stride(from: visibleStart, through: visibleEnd, by: 86_400).map { $0 }
    }

    func starts(on date: Date) -> Bool {
        guard let start = MoilCalendarDate.date(from: self.date) else { return false }
        return Calendar.current.isDate(start, inSameDayAs: date)
    }

    func ends(on date: Date) -> Bool {
        guard let end = MoilCalendarDate.date(from: endDate) else { return false }
        return Calendar.current.isDate(end, inSameDayAs: date)
    }
}

/// API의 `yyyy-MM-dd` 값과 ISO-8601 날짜 시간을 모두 로컬 달력 날짜로 정규화합니다.
/// 서버가 UTC 날짜 시간을 반환해도 화면과 다음 수정 요청에서 하루가 밀리지 않게 합니다.
private enum MoilCalendarDate {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func string(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func string(from date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return string(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    static func date(from value: String) -> Date? {
        guard let components = dateOnlyComponents(from: value) else { return nil }
        return calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day))
    }

    static func normalizedString(from value: String) -> String? {
        if let dateOnly = dateOnlyComponents(from: value) {
            return string(year: dateOnly.year, month: dateOnly.month, day: dateOnly.day)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: value) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: value)
        }() ?? localDate(from: value)
        guard let date else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        return string(year: year, month: month, day: day)
    }

    static func day(from date: String) -> Int? {
        dateOnlyComponents(from: date)?.day
    }

    static func nextDayString(from value: String) -> String? {
        guard let components = dateOnlyComponents(from: value),
              let date = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day)),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
        guard let year = nextComponents.year, let month = nextComponents.month, let day = nextComponents.day else { return nil }
        return string(year: year, month: month, day: day)
    }

    static func previousDayString(from value: String) -> String? {
        guard let date = date(from: value), let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return string(from: previous)
    }

    private static func dateOnlyComponents(from value: String) -> (year: Int, month: Int, day: Int)? {
        // 서버가 `yyyy-MM-dd` 또는 `yyyy-MM-ddTHH:mm:ssZ`를 반환해도
        // 원문 날짜를 우선 사용해 UTC 변환으로 전날로 밀리는 일을 막습니다.
        let datePrefix = String(value.prefix(10))
        let parts = datePrefix.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              (1...12).contains(month),
              (1...31).contains(day) else { return nil }
        return (year, month, day)
    }

    private static func localDate(from value: String) -> Date? {
        let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"]

        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .autoupdatingCurrent
            formatter.dateFormat = format

            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
}

#Preview("캘린더") {
    CalendarView()
        .environmentObject(MoilGroupStore())
        .environmentObject(MoilSessionStore())
        .environmentObject(MoilEventStore())
}

private struct DayScheduleSheet: View {
    let day: Int
    let dateTitle: String
    let events: [CalendarEvent]
    let onAdd: () -> Void
    let onSelect: (CalendarEvent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateTitle)
                        .font(MoilTypography.bold(18))
                    Text("• 오늘")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                }
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .frame(width: 48, height: 48)
                        .background(MoilColor.textPrimary.opacity(0.12))
                        .clipShape(Circle())
                }
                .foregroundStyle(MoilColor.textPrimary)
                .accessibilityLabel("일정 추가")
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ForEach(events) { event in
                Button { onSelect(event) } label: {
                    HStack(spacing: 14) {
                        Circle().fill(event.color).frame(width: 10, height: 10)
                        Text(event.isAllDay ? "하루 종일" : "\(event.startTime ?? "09:00")\n\(event.endTime ?? "")")
                            .font(MoilTypography.regular(13))
                            .foregroundStyle(MoilColor.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(width: 46, alignment: .leading)
                        Text(event.title)
                            .font(MoilTypography.bold(16))
                            .foregroundStyle(MoilColor.textPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        AvatarDots(count: max(event.memberIDs.count, 1))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(MoilColor.textPrimary)
                    }
                    .padding(.horizontal, 28)
                    .frame(minHeight: 110)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider().padding(.horizontal, 28)
            }
            Spacer()
        }
        .background(MoilColor.surface)
    }
}

private struct AvatarDots: View {
    let count: Int
    var body: some View {
        HStack(spacing: -6) {
            ForEach(0..<min(count, 3), id: \.self) { index in
                Circle()
                    .fill([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green][index])
                    .frame(width: 26, height: 26)
                    .overlay { Circle().stroke(MoilColor.surface, lineWidth: 2) }
            }
        }
    }
}

private struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let members: [MoilRemoteMember]
    let onSave: (Date, Date, String, Bool, String?, String?, String?, String?, [String]) -> Void
    @State private var title = ""
    @State private var isAllDay = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location = ""
    @State private var memo = ""
    @State private var inputTarget: ScheduleInputTarget?
    @State private var isTimeEditorPresented = false
    @State private var isDateEditorPresented = false
    @State private var selectedMemberIDs: Set<String>

    init(
        initialDate: Date,
        members: [MoilRemoteMember],
        onSave: @escaping (Date, Date, String, Bool, String?, String?, String?, String?, [String]) -> Void
    ) {
        self.members = members
        self.onSave = onSave
        let currentUser = members.filter(\.isMe).map(\.id)
        _selectedMemberIDs = State(initialValue: Set(currentUser.isEmpty ? members.prefix(1).map(\.id) : currentUser))
        _startTime = State(initialValue: Self.time(hour: 9))
        _endTime = State(initialValue: Self.time(hour: 10))
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && !selectedMemberIDs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: dismiss.callAsFunction)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text("새 일정").font(MoilTypography.semibold(16))
                Spacer()
                Button("저장") {
                    onSave(
                        startDate,
                        endDate,
                        trimmedTitle,
                        isAllDay,
                        isAllDay ? nil : Self.timeString(startTime),
                        isAllDay ? nil : Self.timeString(endTime),
                        location.nilIfBlank,
                        memo.nilIfBlank,
                        Array(selectedMemberIDs)
                    )
                    dismiss()
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(canSave ? MoilColor.primary : MoilColor.textTertiary)
                    .disabled(!canSave)
            }
            .padding(.horizontal, 18)
            .padding(.top, 34)
            .padding(.bottom, 18)

            ScrollView {
                VStack(spacing: 0) {
                    TextField("일정 제목", text: $title)
                        .moilField()
                        .padding(.bottom, 8)

                    ScheduleRow(title: "날짜", value: Self.displayDateRange(start: startDate, end: endDate))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isDateEditorPresented = true
                        }
                    ScheduleRow(title: "시간", value: Self.displayTimeRange(start: startTime, end: endTime))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isTimeEditorPresented = true
                        }

                    ScheduleRow(title: "위치", value: location.nilIfBlank ?? "추가", secondary: location.nilIfBlank == nil)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            inputTarget = .location
                        }

                    ScheduleRow(title: "메모", value: memo.nilIfBlank ?? "추가", secondary: memo.nilIfBlank == nil)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            inputTarget = .memo
                        }

                    VStack(alignment: .leading, spacing: 18) {
                        Text("누구와 공유할까요")
                            .font(MoilTypography.semibold(13))
                            .foregroundStyle(MoilColor.textSecondary)
                        HStack(spacing: 14) {
                            ForEach(members) { member in
                                Button { toggle(member.id) } label: {
                                    VStack(spacing: 6) {
                                        MoilAvatar(color: MoilAvatarColor.color(for: member.colorId), size: 44)
                                            .overlay { Circle().stroke(selectedMemberIDs.contains(member.id) ? MoilColor.primary : .clear, lineWidth: 3).padding(-4) }
                                        Text(member.nickname).font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                }
                .padding(.horizontal, 18)
            }
        }
        .background(MoilColor.surface)
        .sheet(item: $inputTarget) { target in
            ScheduleTextInputSheet(
                title: target.title,
                placeholder: target.placeholder,
                text: target == .location ? $location : $memo,
                allowsMultipleLines: target == .memo
            )
            .presentationDetents([target == .memo ? .medium : .height(260)])
        }
        .sheet(isPresented: $isTimeEditorPresented) {
            ScheduleTimeInputSheet(
                startTime: $startTime,
                endTime: $endTime,
                onClose: { isTimeEditorPresented = false }
            )
            .presentationDetents([.height(420)])
        }
        .sheet(isPresented: $isDateEditorPresented) {
            ScheduleDateRangeInputSheet(
                startDate: $startDate,
                endDate: $endDate,
                onClose: { isDateEditorPresented = false }
            )
            .presentationDetents([.height(420)])
        }
    }

    private func toggle(_ memberID: String) {
        if selectedMemberIDs.contains(memberID) { selectedMemberIDs.remove(memberID) } else { selectedMemberIDs.insert(memberID) }
    }

    private static func time(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private static func timeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private static func displayTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        let endFormatter = DateFormatter()
        endFormatter.locale = Locale(identifier: "ko_KR")
        endFormatter.dateFormat = "h:mm"
        return "\(formatter.string(from: start)) – \(endFormatter.string(from: end))"
    }

    private static func displayDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        let normalizedEnd = max(start, end)
        return Calendar.current.isDate(start, inSameDayAs: normalizedEnd)
            ? formatter.string(from: start)
            : "\(formatter.string(from: start)) – \(formatter.string(from: normalizedEnd))"
    }
}

private enum ScheduleInputTarget: Identifiable, Equatable {
    case location
    case memo

    var id: Self { self }
    var title: String { self == .location ? "위치" : "메모" }
    var placeholder: String { self == .location ? "위치를 입력하세요" : "메모를 입력하세요" }
}

private struct ScheduleTextInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    @Binding var text: String
    let allowsMultipleLines: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: dismiss.callAsFunction)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text(title).font(MoilTypography.semibold(16))
                Spacer()
                Button("완료", action: dismiss.callAsFunction)
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(MoilColor.primary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 18)

            TextField(placeholder, text: $text, axis: allowsMultipleLines ? .vertical : .horizontal)
                .moilField()
                .lineLimit(allowsMultipleLines ? 3...6 : 1...1)
                .padding(.horizontal, 18)
            Spacer()
        }
        .background(MoilColor.surface)
    }
}

private struct ScheduleDateRangeInputSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onClose: () -> Void
    @State private var displayedMonth: Date
    @State private var selectedDates: Set<DateComponents>

    private let calendar: Calendar
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    init(startDate: Binding<Date>, endDate: Binding<Date>, onClose: @escaping () -> Void) {
        _startDate = startDate
        _endDate = endDate
        self.onClose = onClose
        var koreanCalendar = Calendar(identifier: .gregorian)
        koreanCalendar.locale = Locale(identifier: "ko_KR")
        koreanCalendar.timeZone = .autoupdatingCurrent
        calendar = koreanCalendar
        let start = koreanCalendar.dateComponents([.year, .month, .day], from: startDate.wrappedValue)
        let end = koreanCalendar.dateComponents([.year, .month, .day], from: endDate.wrappedValue)
        _selectedDates = State(initialValue: Set([start, end]))
        _displayedMonth = State(initialValue: startDate.wrappedValue)
    }

    private var selectedDays: [Date] {
        selectedDates.compactMap { calendar.date(from: $0) }.sorted()
    }

    private var monthDays: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var leadingBlankDays: Int {
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    private var slotCount: Int {
        Int(ceil(Double(leadingBlankDays + monthDays) / 7)) * 7
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: onClose)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text("날짜").font(MoilTypography.semibold(16))
                Spacer()
                Button("완료") {
                    let days = selectedDays
                    if let first = days.first {
                        startDate = first
                        endDate = days.last ?? first
                    }
                    onClose()
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(MoilColor.primary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 24)

            HStack {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .frame(width: 40, height: 40)
                Spacer()
                Text(displayedMonth.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "ko_KR"))))
                    .font(MoilTypography.semibold(17))
                Spacer()
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                    .frame(width: 40, height: 40)
            }
            .foregroundStyle(MoilColor.textPrimary)
            .padding(.horizontal, 24)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                    Text(weekday)
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textSecondary)
                }
                ForEach(0..<slotCount, id: \.self) { slot in
                    let day = slot - leadingBlankDays + 1
                    if (1...monthDays).contains(day), let date = date(for: day) {
                        dayButton(date: date, day: day)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            Text(selectionHint)
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 18)
            Spacer()
        }
        .background(MoilColor.surface)
    }

    private var selectionHint: String {
        switch selectedDays.count {
        case 0: "날짜를 선택해주세요"
        case 1: "다른 날짜를 선택하면 기간 일정이 됩니다"
        default: "선택된 날짜를 다시 누르면 선택이 해제됩니다"
        }
    }

    private func date(for day: Int) -> Date? {
        calendar.date(bySetting: .day, value: day, of: displayedMonth)
    }

    private func dayButton(date: Date, day: Int) -> some View {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let isSelected = selectedDates.contains(components)
        let isInRange = selectedDays.count == 2 && date >= selectedDays[0] && date <= selectedDays[1]
        return Button { toggle(date) } label: {
            Text("\(day)")
                .font(MoilTypography.regular(15))
                .foregroundStyle(isSelected ? Color.white : MoilColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(isSelected ? MoilColor.primary : (isInRange ? MoilColor.primary.opacity(0.18) : .clear))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ date: Date) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        if selectedDates.contains(components) {
            selectedDates.remove(components)
        } else if selectedDates.count < 2 {
            selectedDates.insert(components)
        } else {
            selectedDates = [components]
        }
    }

    private func moveMonth(_ value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}

private struct ScheduleTimeInputSheet: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    let onClose: () -> Void
    @State private var isEditingEndTime = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: onClose)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text("시간").font(MoilTypography.semibold(16))
                Spacer()
                Button("완료", action: onClose)
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(MoilColor.primary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 8)

            HStack(spacing: 10) {
                timeOption(title: "시작 시간", value: displayTime(startTime), isSelected: !isEditingEndTime) {
                    isEditingEndTime = false
                }
                timeOption(title: "종료 시간", value: displayTime(endTime), isSelected: isEditingEndTime) {
                    isEditingEndTime = true
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 36)

            Group {
                if isEditingEndTime {
                    DatePicker("종료 시간", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                } else {
                    DatePicker("시작 시간", selection: $startTime, displayedComponents: .hourAndMinute)
                }
            }
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(height: 180)
            .clipped()
            .padding(.top, 16)
            Spacer()
        }
        .background(MoilColor.surface)
    }

    private func timeOption(title: String, value: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(MoilTypography.regular(13))
                Text(value).font(MoilTypography.semibold(17))
            }
            .foregroundStyle(isSelected ? MoilColor.textPrimary : MoilColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? MoilColor.textPrimary.opacity(0.12) : MoilColor.textPrimary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? MoilColor.textSecondary.opacity(0.45) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func displayTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

private struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEvent
    let onSave: (String) -> Void
    let onDelete: () -> Void
    @State private var title: String
    @State private var isEditing = false

    init(event: CalendarEvent, onSave: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: event.title)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(event.owner, systemImage: "circle.fill")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(event.color)
                Spacer()
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(MoilColor.textSecondary)
            }
            .padding(.bottom, 18)

            if isEditing {
                TextField("일정 제목", text: $title)
                    .moilField()
                    .padding(.bottom, 12)
            } else {
                Text(event.title)
                    .font(MoilTypography.bold(24))
                    .foregroundStyle(MoilColor.textPrimary)
                    .padding(.bottom, 20)
            }

            DetailRow(icon: "calendar", title: formattedDate, value: event.isAllDay ? "하루 종일" : timeTitle)
            DetailRow(icon: "location", title: event.location ?? "위치 없음", value: event.location == nil ? nil : "지도")
            HStack(spacing: 10) {
                Image(systemName: "person.2")
                    .foregroundStyle(MoilColor.textSecondary)
                Text("참여자 \(max(event.memberIDs.count, 1))명")
                    .font(MoilTypography.regular(15))
                Spacer()
                AvatarDots(count: max(event.memberIDs.count, 1))
            }
            .padding(.vertical, 16)
            Divider()
            Text("메모")
                .font(MoilTypography.regular(15))
                .foregroundStyle(MoilColor.textSecondary)
                .padding(.top, 18)
            Text(event.memo ?? "등록된 메모가 없어요.")
                .font(MoilTypography.regular(14))
                .foregroundStyle(event.memo == nil ? MoilColor.textTertiary : MoilColor.textPrimary)
                .padding(.top, 8)
            Spacer(minLength: 16)
            HStack(spacing: 12) {
                Button(isEditing ? "저장" : "수정") {
                    if isEditing { onSave(trimmedTitle); dismiss() }
                    else { isEditing = true }
                }
                .disabled(isEditing && trimmedTitle.isEmpty)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(MoilColor.textPrimary.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
                Button("삭제", role: .destructive) { onDelete(); dismiss() }
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(MoilColor.error.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .foregroundStyle(MoilColor.textPrimary)
        .padding(24)
        .background(MoilColor.surface)
    }

    private var formattedDate: String { event.date.replacingOccurrences(of: "-", with: ".") }
    private var timeTitle: String { "\(event.startTime ?? "09:00") – \(event.endTime ?? "10:00")" }
}

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String?
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 18).foregroundStyle(MoilColor.textSecondary)
            Text(title).font(MoilTypography.regular(15)).foregroundStyle(MoilColor.textSecondary)
            Spacer()
            if let value { Text(value).font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textTertiary) }
        }
        .padding(.vertical, 15)
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct ScheduleRow: View {
    let title: String
    let value: String
    var secondary = false

    var body: some View {
        HStack {
            Text(title).font(MoilTypography.regular(15))
            Spacer()
            Text(value).font(MoilTypography.regular(15)).foregroundStyle(secondary ? MoilColor.textTertiary : MoilColor.textSecondary)
        }
        .padding(.horizontal, 18).frame(height: 46)
        .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }
    }
}

private struct ScheduleSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var eventStore: MoilEventStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let groupId: String?
    let month: String
    @State private var query = ""
    @State private var errorMessage: String?

    private var events: [CalendarEvent] {
        eventStore.events(groupId: groupId, month: month).compactMap(CalendarEvent.init(remote:))
    }

    private var filteredEvents: [CalendarEvent] {
        guard !query.isEmpty else { return events }
        return events.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.owner.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(MoilColor.textTertiary)
                    TextField("일정 검색", text: $query)
                }
                .moilField()
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if filteredEvents.isEmpty {
                    Spacer()
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(MoilColor.textTertiary)
                    Text("검색 결과가 없어요")
                        .font(MoilTypography.semibold(16))
                        .padding(.top, 12)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredEvents) { event in
                                HStack(spacing: 12) {
                                    Circle().fill(event.color).frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title).font(MoilTypography.semibold(16))
                                        Text("\(event.date) · \(event.owner)")
                                            .font(MoilTypography.regular(13))
                                            .foregroundStyle(MoilColor.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(MoilColor.textTertiary)
                                }
                                .padding(16)
                                .background(MoilColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(MoilColor.background.ignoresSafeArea())
            .navigationTitle("일정 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(MoilColor.textPrimary)
                    }
                }
            }
        }
        .task(id: "\(groupId ?? "")-\(month)") {
            guard let groupId else { return }
            do {
                try await eventStore.load(groupId: groupId, month: month, using: sessionStore.service())
            } catch {
                guard !error.isRequestCancellation else { return }
                errorMessage = error.localizedDescription
            }
        }
        .alert("서버 오류", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
