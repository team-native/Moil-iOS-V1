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
    @State private var isScheduleSearchPresented = false
    @State private var selectedDay: Int?
    @State private var isMemberViewPresented = false
    @State private var isMyPagePresented = false
    @State private var isCreateGroupPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var isEmptyCalendarPresented = false
    @State private var shouldOpenCreateGroupAfterProfile = false
    @State private var displayedMonth = Date()
    @State private var serverError: String?

    /// 날짜 칸마다 전체 목록을 다시 변환하지 않도록 한 번만 묶어 둡니다.
    @MainActor
    private var eventsByDay: [Int: [CalendarEvent]] {
        Dictionary(
            grouping: eventStore.events(groupId: groupStore.selectedGroupId, month: monthRequestValue)
                .compactMap(CalendarEvent.init(remote:)),
            by: \.day
        )
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
    private let dayCellMinHeight: CGFloat = 92

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
                        .contentShape(Rectangle())
                        Spacer()
                        Button { isScheduleSearchPresented = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(MoilColor.textPrimary)
                                .frame(width: 44, height: 44, alignment: .trailing)
                                .contentShape(Rectangle())
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
                                        .contentShape(Rectangle())
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
                                        .contentShape(Rectangle())
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
                            Text(monthTitle).font(MoilTypography.heavy(32))
                            Text(yearTitle).font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
                        }
                        Spacer()
                        Button { moveMonth(by: -1) } label: {
                            Image(systemName: "chevron.left")
                            .frame(width: 30, height: 30)
                            .background(MoilColor.background)
                            .clipShape(Circle())
                            .overlay { Circle().stroke(MoilColor.textTertiary.opacity(0.35), lineWidth: 1) }
                            .contentShape(Circle())
                        }
                        .foregroundStyle(MoilColor.textPrimary)
                        Button { moveMonth(by: 1) } label: {
                            Image(systemName: "chevron.right")
                            .frame(width: 30, height: 30)
                            .background(MoilColor.background)
                            .clipShape(Circle())
                            .overlay { Circle().stroke(MoilColor.textTertiary.opacity(0.35), lineWidth: 1) }
                            .contentShape(Circle())
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
                        let dayEvents = eventsByDay
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(0..<(calendarRowCount * 7), id: \.self) { slot in
                                let day = slot - leadingBlankDays + 1
                                if (1...daysInMonth).contains(day) {
                                    calendarDay(day, events: dayEvents[day] ?? [])
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
        .moilBottomSheet(
            item: Binding(get: { selectedDay.map(DayScheduleSelection.init(day:)) }, set: { selectedDay = $0?.day }),
            height: MoilSheetMetrics.dayHeight,
            background: MoilSheetMetrics.sheetBackground
        ) { selection in
            DayScheduleSheetContainer(
                day: selection.day,
                year: displayedYear,
                month: displayedMonthValue,
                events: eventsByDay[selection.day] ?? [],
                members: groupStore.members(for: groupStore.selectedGroupId),
                onCreate: { draft in createEvent(draft) },
                onUpdate: { event, draft in updateEvent(event, draft: draft) },
                onDelete: { event in deleteEvent(event) },
                onLoadDetail: { event in await eventDetail(event) }
            )
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
    }

    private var monthRequestValue: String {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
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

    private func isToday(_ day: Int) -> Bool {
        MoilCalendarDate.isToday(year: displayedYear, month: displayedMonthValue, day: day)
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    private var displayedMonthValue: Int {
        calendar.component(.month, from: displayedMonth)
    }

    private func createEvent(_ draft: ScheduleDraft) {
        guard let groupId = groupStore.selectedGroupId, let groupID = Int(groupId) else {
            serverError = "그룹 정보를 불러오지 못했어요."
            return
        }
        let memberIDs = draft.memberIDs.compactMap(Int.init)
        guard !memberIDs.isEmpty else {
            serverError = "일정을 공유할 구성원을 1명 이상 선택해주세요."
            return
        }
        Task {
            do {
                _ = try await sessionStore.service().createEvent(CreateEventRequest(
                    groupId: groupID,
                    title: draft.title,
                    date: draft.dateString,
                    isAllDay: false,
                    startTime: draft.startTime,
                    endTime: draft.endTime,
                    location: draft.location.isEmpty ? nil : draft.location,
                    memo: draft.memo.isEmpty ? nil : draft.memo,
                    sharedMemberIds: memberIDs
                ))
                await loadEvents()
            } catch { serverError = error.localizedDescription }
        }
    }

    private func updateEvent(_ event: CalendarEvent, draft: ScheduleDraft) {
        let memberIDs = draft.memberIDs.compactMap(Int.init)
        guard !memberIDs.isEmpty else {
            serverError = "일정을 공유할 구성원을 1명 이상 선택해주세요."
            return
        }
        Task {
            do {
                try await sessionStore.service().updateEvent(id: event.id, request: UpdateEventRequest(
                    title: draft.title,
                    date: draft.dateString,
                    isAllDay: false,
                    startTime: draft.startTime,
                    endTime: draft.endTime,
                    location: draft.location.isEmpty ? nil : draft.location,
                    memo: draft.memo.isEmpty ? nil : draft.memo,
                    sharedMemberIds: memberIDs
                ))
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

    /// 목록 응답에는 메모·참여자가 빠져 있을 수 있어 상세를 한 번 더 불러옵니다.
    private func eventDetail(_ event: CalendarEvent) async -> CalendarEvent {
        guard let remote = try? await sessionStore.service().event(id: event.id),
              let detail = CalendarEvent(remote: remote) else { return event }
        return detail
    }

    private func calendarDay(_ day: Int, events: [CalendarEvent]) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) { selectedDay = day }
        } label: {
            VStack(alignment: .center, spacing: 8) {
                Text("\(day)")
                    .font(isToday(day) ? MoilTypography.bold(15) : MoilTypography.regular(15))
                    .foregroundStyle(isToday(day) ? .white : MoilColor.textPrimary)
                    .frame(width: 32, height: 32, alignment: .center)
                    // 오늘 날짜는 동그라미로 표시합니다.
                    .background { if isToday(day) { Circle().fill(MoilColor.primary) } }
                ForEach(events) { event in
                    eventChip(event)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: dayCellMinHeight, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func eventChip(_ event: CalendarEvent) -> some View {
        Text(event.shortTitle)
            .font(MoilTypography.regular(10))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(event.color.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

}

#Preview("캘린더") {
    CalendarView()
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
        VStack(spacing: 0) {
            MoilInlineHeader(title: "일정 검색", onBack: dismiss.callAsFunction)
            VStack(spacing: 0) {
                MoilTextField(placeholder: "일정 검색", text: $query)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(MoilColor.textTertiary)
                            .padding(.trailing, 16)
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MoilColor.background.ignoresSafeArea())
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
