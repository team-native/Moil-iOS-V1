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

    private var calendarRowCount: Int {
        let occupiedCells = leadingBlankDays + daysInMonth
        return max(5, Int(ceil(Double(occupiedCells) / 7)))
    }

    private var dayCellHeight: CGFloat {
        calendarRowCount == 6 ? 88 : 104
    }

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
                    LazyVGrid(columns: columns, spacing: 9) {
                        ForEach(["일","월","화","수","목","금","토"], id: \.self) { Text($0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }
                        ForEach(0..<(calendarRowCount * 7), id: \.self) { slot in
                            let day = slot - leadingBlankDays + 1
                            if (1...daysInMonth).contains(day) {
                                calendarDay(day)
                            } else {
                                Color.clear.frame(height: dayCellHeight)
                            }
                        }
                    }
                    .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
                    Spacer()
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
            ScheduleComposerView(day: scheduleDraftDay) { day, title in
                createEvent(day: day, title: title)
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
            ScheduleSearchView()
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
            serverError = error.localizedDescription
        }
    }

    private func createEvent(day: Int, title: String) {
        guard let groupId = groupStore.selectedGroupId else { return }
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        let date = calendar.date(from: components)?.formatted(.iso8601.year().month().day()) ?? ""
        Task {
            do {
                _ = try await sessionStore.service().createEvent(CreateEventRequest(groupId: groupId, title: title, date: date, isAllDay: true, startTime: nil, endTime: nil, location: nil, sharedMemberIds: []))
                await loadEvents()
            } catch { serverError = error.localizedDescription }
        }
    }

    private func updateEvent(_ event: CalendarEvent, title: String) {
        guard let groupId = groupStore.selectedGroupId else { return }
        Task {
            do {
                let request = CreateEventRequest(groupId: groupId, title: title, date: event.date, isAllDay: true, startTime: nil, endTime: nil, location: nil, sharedMemberIds: [])
                _ = try await sessionStore.service().updateEvent(id: event.id, request: request)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("\(day)")
                    .font(MoilTypography.regular(15))
                    .frame(width: 32, height: 32, alignment: .center)
                ForEach(events(for: day)) { event in
                    HStack(spacing: 3) {
                        Circle().fill(event.color).frame(width: 6, height: 6)
                        Text(event.owner).font(MoilTypography.regular(10))
                        Text(event.title).font(MoilTypography.regular(10))
                    }
                    .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(height: dayCellHeight, alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            guard let event = events(for: day).first else { return }
            Task { await selectEvent(event) }
        }
    }

    private func events(for day: Int) -> [CalendarEvent] {
        remoteEvents.filter { $0.day == day }
    }
}

private struct CalendarEvent: Identifiable {
    let id: String
    let day: Int
    let owner: String
    let title: String
    let date: String
    let color: Color

    init?(remote: MoilRemoteEvent) {
        let parts = remote.date.split(separator: "-")
        guard let finalPart = parts.last, let eventDay = Int(finalPart.prefix(2)) else { return nil }
        id = remote.id
        day = eventDay
        owner = remote.ownerName ?? "나"
        title = remote.title
        date = remote.date
        color = MoilAvatarColor.color(for: remote.colorId)
    }
}

#Preview("캘린더") {
    CalendarView()
}

private struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let day: Int
    let onSave: (Int, String) -> Void
    @State private var title = ""
    @State private var allDay = false
    @State private var selectedMembers: Set<String> = ["아빠", "나"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: dismiss.callAsFunction)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text("새 일정").font(MoilTypography.semibold(16))
                Spacer()
                Button("저장") {
                    onSave(day, title.isEmpty ? "새 일정" : title)
                    dismiss()
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(MoilColor.primary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            TextField("일정 제목", text: $title)
                .font(MoilTypography.semibold(21))
                .padding(.horizontal, 18)
                .frame(height: 58)
                .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }

            ScheduleRow(title: "날짜", value: "7월 \(day)일")
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
                    ForEach([("아빠", MoilAvatarColor.blue), ("엄마", MoilAvatarColor.red), ("나", MoilAvatarColor.green), ("동생", MoilAvatarColor.orange)], id: \.0) { member in
                        Button { toggle(member.0) } label: {
                            VStack(spacing: 6) {
                                MoilAvatar(color: member.1, size: 44)
                                    .overlay { Circle().stroke(selectedMembers.contains(member.0) ? MoilColor.primary : .clear, lineWidth: 3).padding(-4) }
                                Text(member.0).font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18).padding(.top, 16)
            Spacer()
        }
        .background(MoilColor.surface)
    }

    private func toggle(_ member: String) {
        if selectedMembers.contains(member) { selectedMembers.remove(member) } else { selectedMembers.insert(member) }
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
                Button("저장") { onSave(title.isEmpty ? event.title : title); dismiss() }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 12))
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
    @State private var query = ""

    private let events: [(day: String, owner: String, title: String, color: Color)] = [
        ("7월 5일", "엄마", "생일", MoilAvatarColor.red),
        ("7월 9일", "아빠", "가족 저녁", MoilAvatarColor.blue),
        ("7월 28일", "동생", "시험", MoilAvatarColor.yellow)
    ]

    private var filteredEvents: [(day: String, owner: String, title: String, color: Color)] {
        query.isEmpty ? events : events.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.owner.localizedCaseInsensitiveContains(query) }
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
                            ForEach(filteredEvents, id: \.title) { event in
                                HStack(spacing: 12) {
                                    Circle().fill(event.color).frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title).font(MoilTypography.semibold(16))
                                        Text("\(event.day) · \(event.owner)")
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
    }
}
