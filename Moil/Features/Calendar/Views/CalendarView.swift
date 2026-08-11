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

    @MainActor
    private var remoteEvents: [CalendarEvent] {
        eventStore.events(groupId: groupStore.selectedGroupId, month: monthRequestValue)
            .compactMap(CalendarEvent.init(remote:))
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var leadingBlankDays: Int {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let firstDay = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 1)) ?? displayedMonth
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    /// 월이 바뀌어도 기본 레이아웃이 같도록 항상 여섯 줄을 그립니다.
    private let calendarRowCount = 6

    /// 일정이 많은 날은 이 높이보다 커지고, 늘어난 만큼 달력이 세로로 스크롤됩니다.
    private let dayCellMinHeight: CGFloat = 88

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).locale(Locale(identifier: "ko_KR")))
    }

    private var yearTitle: String {
        displayedMonth.formatted(.dateTime.year().locale(Locale(identifier: "ko_KR")))
    }

    /// The empty state paints its own fixed dark background, so the tab bar has to follow it.
    private var tabBarStyle: MoilTabBarStyle {
        groupStore.groups.isEmpty ? .dark : .standard
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
                                Divider()
                                Button {
                                    isGroupMenuPresented = false
                                    if let onCreateGroup {
                                        onCreateGroup()
                                    } else {
                                        isCreateGroupPresented = true
                                    }
                                } label: {
                                    Label("새 그룹 만들기", systemImage: "plus")
                                        .font(MoilTypography.semibold(14))
                                        .padding(.horizontal, 14)
                                        .frame(height: 46)
                                }
                                .foregroundStyle(MoilColor.primary)
                            }
                            .frame(width: 180)
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
                            Text(monthTitle).font(MoilTypography.bold(32))
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
                        ForEach(["일","월","화","수","목","금","토"], id: \.self) { Text($0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                    .padding(.bottom, 9)
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 9) {
                            ForEach(0..<(calendarRowCount * 7), id: \.self) { slot in
                                let day = slot - leadingBlankDays + 1
                                if (1...daysInMonth).contains(day) {
                                    calendarDay(day)
                                } else {
                                    Color.clear.frame(minHeight: dayCellMinHeight)
                                }
                            }
                        }
                        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .moilTabScreenLayout(selected: .calendar, style: tabBarStyle, isTabBarVisible: showsTabBar) { tab in
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
                day: scheduleDraftDay,
                dateTitle: scheduleDraftDateTitle,
                members: groupStore.members(for: groupStore.selectedGroupId)
            ) { day, title, isAllDay, memberIDs in
                createEvent(day: day, title: title, isAllDay: isAllDay, sharedMemberIDs: memberIDs)
            }
                .presentationDetents([.height(463)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedEvent) { event in
            EventEditorView(event: event) { title in
                updateEvent(event, title: title)
            } onDelete: {
                deleteEvent(event)
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isMemberViewPresented) { MemberView() }
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
            GroupJoinCodeView {
                isJoinGroupPresented = false
                isJoinProfilePresented = true
            }
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
    }

    private var monthRequestValue: String {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private var scheduleDraftDateTitle: String {
        let components = calendar.dateComponents([.month], from: displayedMonth)
        return "\(components.month ?? 1)월 \(scheduleDraftDay)일"
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

    private func createEvent(day: Int, title: String, isAllDay: Bool, sharedMemberIDs: [String]) {
        guard let groupId = groupStore.selectedGroupId, let groupID = Int(groupId) else {
            serverError = "그룹 정보를 불러오지 못했어요."
            return
        }
        let memberIDs = sharedMemberIDs.compactMap(Int.init)
        guard !memberIDs.isEmpty else {
            serverError = "일정을 공유할 구성원을 1명 이상 선택해주세요."
            return
        }
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let year = components.year, let month = components.month else {
            serverError = "일정 날짜를 만들지 못했어요."
            return
        }
        // 날짜만 있는 API 값은 Date(시간대)를 거치지 않아야 KST에서 전날로 밀리지 않습니다.
        let date = MoilCalendarDate.string(year: year, month: month, day: day)
        Task {
            do {
                _ = try await sessionStore.service().createEvent(CreateEventRequest(
                    groupId: groupID,
                    title: title,
                    date: date,
                    isAllDay: isAllDay,
                    startTime: isAllDay ? nil : "09:00",
                    endTime: isAllDay ? nil : "10:00",
                    location: nil,
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
        Task {
            do {
                let request = UpdateEventRequest(
                    title: title,
                    date: event.date,
                    isAllDay: event.isAllDay,
                    startTime: event.startTime,
                    endTime: event.endTime,
                    location: event.location,
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

    private func calendarDay(_ day: Int) -> some View {
        Button {
            scheduleDraftDay = day
            isScheduleComposerPresented = true
        } label: {
            VStack(alignment: .center, spacing: 4) {
                Text("\(day)")
                    .font(MoilTypography.regular(15))
                    .frame(width: 32, height: 32, alignment: .center)
                ForEach(events(for: day)) { event in
                    eventChip(event)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: dayCellMinHeight, alignment: .top)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            guard let event = events(for: day).first else { return }
            Task { await selectEvent(event) }
        }
    }

    private func eventChip(_ event: CalendarEvent) -> some View {
        Text(event.shortTitle)
            .font(MoilTypography.regular(10))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(event.color.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func events(for day: Int) -> [CalendarEvent] {
        remoteEvents.filter { $0.day == day }
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
    let color: Color
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let memberIDs: [Int]

    init?(remote: MoilRemoteEvent) {
        guard let normalizedDate = MoilCalendarDate.normalizedString(from: remote.date),
              let eventDay = MoilCalendarDate.day(from: normalizedDate) else { return nil }
        id = remote.id
        day = eventDay
        owner = remote.ownerName ?? "나"
        title = remote.title
        date = normalizedDate
        color = MoilAvatarColor.color(for: remote.colorId)
        isAllDay = remote.isAllDay
        startTime = remote.startTime
        endTime = remote.endTime
        location = remote.location
        memberIDs = remote.members.compactMap { $0.id.flatMap(Int.init) }
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
}

private struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let day: Int
    let dateTitle: String
    let members: [MoilRemoteMember]
    let onSave: (Int, String, Bool, [String]) -> Void
    @State private var title = ""
    @State private var allDay = false
    @State private var selectedMemberIDs: Set<String>

    init(day: Int, dateTitle: String, members: [MoilRemoteMember], onSave: @escaping (Int, String, Bool, [String]) -> Void) {
        self.day = day
        self.dateTitle = dateTitle
        self.members = members
        self.onSave = onSave
        let currentUser = members.filter(\.isMe).map(\.id)
        _selectedMemberIDs = State(initialValue: Set(currentUser.isEmpty ? members.prefix(1).map(\.id) : currentUser))
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
                    onSave(day, trimmedTitle, allDay, Array(selectedMemberIDs))
                    dismiss()
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(canSave ? MoilColor.primary : MoilColor.textTertiary)
                    .disabled(!canSave)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            TextField("일정 제목", text: $title)
                .font(MoilTypography.semibold(21))
                .padding(.horizontal, 18)
                .frame(height: 58)
                .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }

            ScheduleRow(title: "날짜", value: dateTitle)
            HStack {
                Text("하루 종일").font(MoilTypography.regular(15))
                Spacer()
                Toggle("", isOn: $allDay).labelsHidden().tint(MoilColor.primary)
            }
            .padding(.horizontal, 18).frame(height: 50)
            .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }
            ScheduleRow(title: "시간", value: "오전 9:00 – 10:00")
            ScheduleRow(title: "위치", value: "추가", secondary: true)

            VStack(alignment: .leading, spacing: 10) {
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
            .padding(.horizontal, 18).padding(.top, 16)
            Spacer()
        }
        .background(MoilColor.surface)
    }

    private func toggle(_ memberID: String) {
        if selectedMemberIDs.contains(memberID) { selectedMemberIDs.remove(memberID) } else { selectedMemberIDs.insert(memberID) }
    }
}

private struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEvent
    let onSave: (String) -> Void
    let onDelete: () -> Void
    @State private var title: String

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
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("일정 수정").font(MoilTypography.bold(20))
                Spacer()
                Button("닫기", action: dismiss.callAsFunction).foregroundStyle(MoilColor.textSecondary)
            }
            TextField("일정 제목", text: $title)
                .font(MoilTypography.semibold(17))
                .padding(.horizontal, 14).frame(height: 52)
                .background(MoilColor.background).clipShape(RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 10) {
                Button("삭제", role: .destructive) { onDelete(); dismiss() }
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(MoilColor.error.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                Button("저장") { onSave(trimmedTitle); dismiss() }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(trimmedTitle.isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding(20)
        .background(MoilColor.surface)
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
                        .font(MoilTypography.regular(16))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(MoilColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
