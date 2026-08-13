import SwiftUI

/// 캘린더 시트 3종(일별 목록·일정 상세·일정 추가)의 공통 수치입니다.
/// 값은 피그마 `캘린더 · 일별 일정 시트`, `캘린더 · 일정 상세 시트`, `일정 추가` 노드 그대로입니다.
enum MoilSheetMetrics {
    static let dayHeight: CGFloat = 475
    static let detailHeight: CGFloat = 654
    static let composerHeight: CGFloat = 463

    /// 다크 값은 피그마 원본 그대로이고, 라이트 값은 같은 자리에 맞춘 밝은 색입니다.
    static let sheetBackground = Color("SheetBackground")
    /// 새 일정 시트도 일별 목록과 같은 배경을 씁니다.
    static let composerBackground = Color("SheetBackground")
    static let divider = Color("SheetDivider")
    static let handle = Color("SheetHandle")
    static let titleText = MoilColor.textPrimary
    static let subText = MoilColor.textSecondary
    static let addButtonBackground = Color("SheetAddButton")
    static let editButtonBackground = Color("SheetEditButton")
    static let deleteButtonBackground = Color("SheetDeleteButton")
    static let deleteButtonText = Color("SheetDeleteText")
    static let moreAvatarBackground = Color("SheetMoreAvatar")
}

/// 피그마 원본이 아이콘 대신 쓰는 글자들입니다. 그대로 옮겨 씁니다.
enum MoilSheetGlyph {
    static let date = "▣"
    static let location = "⌖"
    static let members = "♧"
    static let memo = "▤"
}

/// 피그마 시트 상단의 손잡이입니다. 기본 드래그 인디케이터 대신 씁니다.
private struct SheetHandle: View {
    var body: some View {
        Capsule()
            .fill(MoilSheetMetrics.handle)
            .frame(width: 54, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
    }
}

// MARK: - 일별 일정 시트

/// 날짜를 누르면 올라오는 그날의 일정 목록입니다. 피그마 `491:950`.
struct DayScheduleSheet: View {
    let dateTitle: String
    let isToday: Bool
    let events: [CalendarEvent]
    let onAdd: () -> Void
    let onSelect: (CalendarEvent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle()

            HStack(spacing: 8) {
                Text(dateTitle)
                    .font(MoilTypography.semibold(17))
                    .foregroundStyle(MoilSheetMetrics.titleText)
                if isToday {
                    Text("• 오늘")
                        .font(MoilTypography.regular(14))
                        .foregroundStyle(MoilSheetMetrics.subText)
                }
                Spacer(minLength: 0)
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MoilSheetMetrics.titleText)
                        .frame(width: 40, height: 40)
                        .background(MoilSheetMetrics.addButtonBackground)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
            // 피그마: 좌우 28, 제목 위 28
            .padding(.horizontal, 28)
            .padding(.top, 13)

            if events.isEmpty {
                Spacer(minLength: 0)
                Text("등록된 일정이 없어요")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilSheetMetrics.subText)
                Spacer(minLength: 0)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(events) { event in
                            Button { onSelect(event) } label: {
                                DayScheduleRow(event: event)
                            }
                            .buttonStyle(.plain)
                            Rectangle()
                                .fill(MoilSheetMetrics.divider)
                                .frame(height: 1)
                                .padding(.horizontal, 28)
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MoilSheetMetrics.sheetBackground)
    }
}

/// 피그마 기준 한 줄 높이 90, 점 11, 시간 칸 폭 59입니다.
private struct DayScheduleRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(event.color)
                .frame(width: 11, height: 11)
            Spacer(minLength: 0).frame(width: 19)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.startTime ?? "하루")
                Text(event.endTime ?? "종일")
            }
            .font(MoilTypography.regular(14))
            .foregroundStyle(MoilSheetMetrics.subText)
            .frame(width: 59, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(MoilTypography.semibold(17))
                    .foregroundStyle(MoilSheetMetrics.titleText)
                    .lineLimit(1)
                if let location = event.location, !location.isEmpty {
                    Text("\(MoilSheetGlyph.location)  \(location)")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilSheetMetrics.subText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 3) {
                ForEach(event.members.prefix(2)) { member in
                    MoilAvatar(color: member.color, size: 25)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(MoilSheetMetrics.titleText)
                .padding(.leading, 12)
        }
        .frame(height: 62)
        .padding(.horizontal, 28)
        .contentShape(Rectangle())
    }
}

// MARK: - 일정 상세 시트

/// 일정을 누르면 올라오는 상세 화면입니다. 피그마 `491:1182`.
struct EventDetailSheet: View {
    let event: CalendarEvent
    let dateTitle: String
    /// 그룹에서 쓰는 내 닉네임입니다. 이 이름이면 저장해 둔 내 이름으로 바꿔 보여 줍니다.
    var myNickname: String?
    let onClose: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(event.color)
                    .frame(width: 12, height: 12)
                Text(ownerText)
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilSheetMetrics.subText)
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(MoilSheetMetrics.subText)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)

            Text(event.title)
                .font(MoilTypography.semibold(24))
                .foregroundStyle(MoilSheetMetrics.titleText)
                .padding(.top, 10)

            HStack(spacing: 0) {
                Text("\(MoilSheetGlyph.date)  \(dateTitle)")
                    .frame(width: 163, alignment: .leading)
                Text(event.timeRangeText)
                Spacer(minLength: 0)
            }
            .font(MoilTypography.regular(14))
            .foregroundStyle(MoilSheetMetrics.subText)
            .padding(.top, 16)

            detailDivider.padding(.top, 14)

            HStack(spacing: 0) {
                Text("\(MoilSheetGlyph.location)  \(event.location?.isEmpty == false ? event.location! : "위치 없음")")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilSheetMetrics.subText)
                    .lineLimit(1)
                Spacer(minLength: 8)
            }
            .frame(height: 22)
            .padding(.top, 12)

            detailDivider.padding(.top, 12)

            HStack(spacing: 0) {
                Text("\(MoilSheetGlyph.members)  참여자 \(event.members.count)명")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilSheetMetrics.subText)
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    ForEach(event.members.prefix(4)) { member in
                        MoilAvatar(color: member.color, size: 28)
                    }
                    if event.members.count > 4 {
                        Text("+\(event.members.count - 4)")
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilSheetMetrics.titleText)
                            .frame(width: 30, height: 30)
                            .background(MoilSheetMetrics.moreAvatarBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .frame(height: 30)
            .padding(.top, 15)

            detailDivider.padding(.top, 15)

            if let memo = event.memo, !memo.isEmpty {
                Text("\(MoilSheetGlyph.memo)  \(memo)")
                    .multilineTextAlignment(.leading)
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilSheetMetrics.subText)
                    .padding(.top, 16)
            }

            HStack(spacing: 0) {
                Button(action: onEdit) {
                    Text("수정")
                        .font(MoilTypography.semibold(16))
                        .foregroundStyle(MoilSheetMetrics.titleText)
                        .frame(width: 88, height: 40)
                        .background(MoilSheetMetrics.editButtonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .contentShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Button(action: onDelete) {
                    Text("삭제")
                        .font(MoilTypography.semibold(16))
                        .foregroundStyle(MoilSheetMetrics.deleteButtonText)
                        .frame(width: 88, height: 40)
                        .background(MoilSheetMetrics.deleteButtonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .contentShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(MoilSheetMetrics.sheetBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        .padding(.horizontal, 36)
    }

    private var ownerText: String {
        guard !event.owner.isEmpty else { return "일정" }
        guard event.owner == myNickname else { return event.owner }
        return MoilLocalAccount.displayName(fallback: event.owner)
    }

    private var detailDivider: some View {
        Rectangle().fill(MoilSheetMetrics.divider).frame(height: 1)
    }

    private func openMap(_ location: String) {
        let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "http://maps.apple.com/?q=\(query)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - 일정 추가·수정 시트

/// 새 일정과 일정 수정이 함께 쓰는 입력 시트입니다. 피그마 `26:2334`.
struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let members: [MoilRemoteMember]
    let onSave: (ScheduleDraft) -> Void

    @State private var eventTitle: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String
    @State private var memo: String
    @State private var selectedMemberIDs: Set<String>

    init(
        title: String = "새 일정",
        date: Date,
        event: CalendarEvent? = nil,
        members: [MoilRemoteMember],
        onSave: @escaping (ScheduleDraft) -> Void
    ) {
        self.title = title
        self.members = members
        self.onSave = onSave
        _eventTitle = State(initialValue: event?.title ?? "")
        _date = State(initialValue: date)
        _startTime = State(initialValue: Self.time(event?.startTime, fallbackHour: 9, on: date))
        _endTime = State(initialValue: Self.time(event?.endTime, fallbackHour: 10, on: date))
        _location = State(initialValue: event?.location ?? "")
        _memo = State(initialValue: event?.memo ?? "")

        if let event, !event.members.isEmpty {
            _selectedMemberIDs = State(initialValue: Set(event.members.map(\.id)))
        } else {
            let me = members.filter(\.isMe).map(\.id)
            _selectedMemberIDs = State(initialValue: Set(me.isEmpty ? members.prefix(1).map(\.id) : me))
        }
    }

    private var trimmedTitle: String {
        eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && !selectedMemberIDs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(MoilSheetMetrics.divider)
                .frame(width: 36, height: 4)
                .padding(.top, 20)

            HStack {
                Button("취소", action: dismiss.callAsFunction)
                    .font(MoilTypography.regular(16))
                    .foregroundStyle(MoilSheetMetrics.subText)
                Spacer(minLength: 0)
                Text(title)
                    .font(MoilTypography.semibold(16))
                    .foregroundStyle(MoilSheetMetrics.titleText)
                Spacer(minLength: 0)
                Button("저장") {
                    onSave(draft)
                    dismiss()
                }
                .font(MoilTypography.bold(16))
                .foregroundStyle(canSave ? MoilColor.primary : MoilSheetMetrics.subText)
                .disabled(!canSave)
            }
            .padding(.top, 16)
            .padding(.bottom, 18)

            // 피그마: 제목은 SemiBold 21, 아래 구분선
            TextField("", text: $eventTitle, prompt: Text("일정 제목").foregroundColor(MoilColor.fieldPlaceholder))
                .font(MoilTypography.semibold(21))
                .foregroundStyle(MoilSheetMetrics.titleText)
                .textInputAutocapitalization(.never)
                .frame(height: 30)
                .padding(.top, 6)
                .padding(.bottom, 13)
            rowDivider

            composerRow("날짜") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            composerRow("시간") {
                HStack(spacing: 2) {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Text("–").foregroundStyle(MoilSheetMetrics.subText)
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            composerRow("위치") {
                TextField("", text: $location, prompt: Text("추가").foregroundColor(MoilSheetMetrics.subText))
                    .font(MoilTypography.regular(15))
                    .foregroundStyle(MoilSheetMetrics.titleText)
                    .multilineTextAlignment(.trailing)
            }
            composerRow("메모") {
                TextField("", text: $memo, prompt: Text("추가").foregroundColor(MoilSheetMetrics.subText))
                    .font(MoilTypography.regular(15))
                    .foregroundStyle(MoilSheetMetrics.titleText)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("누구와 공유할까요")
                    .font(MoilTypography.semibold(13))
                    .foregroundStyle(MoilSheetMetrics.subText)
                HStack(spacing: 14) {
                    ForEach(members) { member in
                        Button { toggle(member.id) } label: {
                            VStack(spacing: 6) {
                                MoilAvatar(color: MoilAvatarColor.color(for: member.colorId), size: 44)
                                    .overlay {
                                        Circle()
                                            .stroke(selectedMemberIDs.contains(member.id) ? MoilColor.primary : .clear, lineWidth: 2)
                                            .padding(-3)
                                    }
                                Text(member.displayName)
                                    .font(selectedMemberIDs.contains(member.id) ? MoilTypography.bold(11) : MoilTypography.regular(11))
                                    .foregroundStyle(MoilSheetMetrics.subText)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, 22)

            Spacer(minLength: 0)
        }
        // 피그마: 좌우 18
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MoilSheetMetrics.composerBackground)
        .tint(MoilColor.primary)
    }

    private var draft: ScheduleDraft {
        ScheduleDraft(
            title: trimmedTitle,
            date: date,
            startTime: Self.string(from: startTime),
            endTime: Self.string(from: endTime),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            memberIDs: Array(selectedMemberIDs)
        )
    }

    private var rowDivider: some View {
        Rectangle().fill(MoilSheetMetrics.divider).frame(height: 1)
    }

    @ViewBuilder
    private func composerRow(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(MoilTypography.regular(15))
                .foregroundStyle(MoilSheetMetrics.titleText)
            Spacer(minLength: 0)
            value()
        }
        .frame(height: 48)
        rowDivider
    }

    private func toggle(_ memberID: String) {
        var updated = selectedMemberIDs
        if updated.contains(memberID) { updated.remove(memberID) } else { updated.insert(memberID) }
        // 모션 없이 즉시 바뀌도록 애니메이션을 끕니다.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { selectedMemberIDs = updated }
    }

    private static func time(_ value: String?, fallbackHour: Int, on date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let parts = (value ?? "").split(separator: ":").compactMap { Int($0) }
        let hour = parts.count == 2 ? parts[0] : fallbackHour
        let minute = parts.count == 2 ? parts[1] : 0
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private static func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// 시트가 상위로 돌려주는 입력값 묶음입니다.
struct ScheduleDraft {
    let title: String
    let date: Date
    let startTime: String
    let endTime: String
    let location: String
    let memo: String
    let memberIDs: [String]
}

extension ScheduleDraft {
    /// API가 받는 `yyyy-MM-dd` 문자열입니다.
    var dateString: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return MoilCalendarDate.string(year: parts.year ?? 0, month: parts.month ?? 1, day: parts.day ?? 1)
    }
}

/// 시트 표시용 식별자입니다.
struct DayScheduleSelection: Identifiable {
    let day: Int
    var id: Int { day }
}

/// 일별 목록 → 일정 상세 → 일정 추가/수정으로 이어지는 시트 묶음입니다.
struct DayScheduleSheetContainer: View {
    let day: Int
    let year: Int
    let month: Int
    let events: [CalendarEvent]
    let members: [MoilRemoteMember]
    let onCreate: (ScheduleDraft) -> Void
    let onUpdate: (CalendarEvent, ScheduleDraft) -> Void
    let onDelete: (CalendarEvent) -> Void
    let onLoadDetail: (CalendarEvent) async -> CalendarEvent

    @State private var detailEvent: CalendarEvent?
    @State private var composerEvent: CalendarEvent?
    @State private var isComposerPresented = false

    private var dateTitle: String {
        MoilCalendarDate.title(year: year, month: month, day: day)
    }

    private var date: Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: components) ?? .now
    }

    var body: some View {
        DayScheduleSheet(
            dateTitle: dateTitle,
            isToday: MoilCalendarDate.isToday(year: year, month: month, day: day),
            events: events,
            onAdd: {
                composerEvent = nil
                isComposerPresented = true
            },
            onSelect: { event in
                Task { detailEvent = await onLoadDetail(event) }
            }
        )
        // 상세는 밑에서 올라오지 않고 화면 가운데에 뜹니다.
        .fullScreenCover(item: $detailEvent) { event in
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { detailEvent = nil }
                EventDetailSheet(
                    event: event,
                    dateTitle: dateTitle,
                    myNickname: members.first(where: \.isMe)?.nickname,
                    onClose: { detailEvent = nil },
                    onEdit: {
                        detailEvent = nil
                        composerEvent = event
                        isComposerPresented = true
                    },
                    onDelete: {
                        detailEvent = nil
                        onDelete(event)
                    }
                )
            }
            .presentationBackground(.clear)
        }
        .moilBottomSheet(
            isPresented: $isComposerPresented,
            height: MoilSheetMetrics.composerHeight,
            background: MoilSheetMetrics.composerBackground
        ) {
            ScheduleComposerView(
                title: composerEvent == nil ? "새 일정" : "일정 수정",
                date: date,
                event: composerEvent,
                members: members
            ) { draft in
                if let composerEvent {
                    onUpdate(composerEvent, draft)
                } else {
                    onCreate(draft)
                }
            }
        }
    }
}
