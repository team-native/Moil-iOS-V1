import SwiftUI
import WatchKit

/// 피그마 "Apple Watch · 월간" 화면입니다.
/// 아이폰 앱(CalendarView)과 동일하게, 달을 하나씩 넘기는 대신 여러 달을 이어붙여
/// 아래로 계속 스크롤할 수 있게 합니다. LazyVStack이라 화면 근처 달만 실제로 그려지고,
/// 각 달의 일정은 화면에 걸릴 때 그 달만 따로 불러옵니다.
struct MonthlyView: View {
    let legend: [FamilyMember]
    let colorForEvent: (MoilRemoteEvent) -> Color
    let loadEvents: (Date) async -> [MoilRemoteEvent]

    @State private var monthsWindow: [Date] = MonthlyView.makeMonthsWindow()
    @State private var scrollPositionMonth: Date?
    @State private var eventsByMonthKey: [String: [MoilRemoteEvent]] = [:]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    /// NavigationStack/ScrollView가 주는 여백 때문에 containerRelativeFrame이 실제
    /// 화면보다 좁게 잡혀 달력 칸이 작아 보이는 문제가 있어, 실제 화면 폭을 기준으로
    /// 7등분해 칸 크기를 직접 계산합니다. 워치마다 화면 크기가 달라 값도 자동으로 맞춰집니다.
    private var cellWidth: CGFloat {
        WKInterfaceDevice.current().screenBounds.width / 7
    }

    private static func makeMonthsWindow() -> [Date] {
        let calendar = Calendar.current
        let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return (-180...180).compactMap { calendar.date(byAdding: .month, value: $0, to: firstOfThisMonth) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(monthsWindow, id: \.self) { month in
                    monthSection(for: month)
                        .id(month)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPositionMonth, anchor: .top)
        .onAppear {
            guard scrollPositionMonth == nil else { return }
            let today = Date()
            scrollPositionMonth = monthsWindow.first { calendar.isDate($0, equalTo: today, toGranularity: .month) }
        }
        .background(WatchColor.background)
    }

    @ViewBuilder
    private func monthSection(for month: Date) -> some View {
        let isFirst = isFirstMonth(month)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(monthTitle(for: month))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)
                Text(yearTitle(for: month))
                    .font(.system(size: 10))
                    .foregroundStyle(WatchColor.textSecondary)
            }
            .padding(.top, isFirst ? 0 : 16)

            if isFirst {
                weekdayHeader
            }

            VStack(spacing: 3) {
                ForEach(Array(weeks(for: month).enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(week) { dayCell($0) }
                    }
                }
            }

            if isFirst {
                legendRow
            }
        }
        .task(id: monthKey(month)) {
            guard eventsByMonthKey[monthKey(month)] == nil else { return }
            eventsByMonthKey[monthKey(month)] = await loadEvents(month)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 8))
                    .foregroundStyle(WatchColor.textSecondary)
                    .frame(width: cellWidth, height: 12)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 8) {
            ForEach(legend) { member in
                HStack(spacing: 4) {
                    Circle()
                        .fill(member.color)
                        .frame(width: 5, height: 5)
                    Text(member.name)
                        .font(.system(size: 8))
                        .foregroundStyle(WatchColor.textSecondary)
                }
            }
        }
    }

    private func dayCell(_ day: MonthDay) -> some View {
        VStack(spacing: 2) {
            if let value = day.day {
                Text("\(value)")
                    .font(.system(size: 10, weight: day.isToday ? .semibold : .regular))
                    .foregroundStyle(WatchColor.textPrimary)
                if let eventColor = day.eventColor {
                    Circle()
                        .fill(eventColor)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(width: cellWidth, height: cellWidth * 0.95)
        .background(day.isToday ? Color("MemberRed") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func isFirstMonth(_ month: Date) -> Bool {
        calendar.isDate(month, equalTo: monthsWindow.first ?? month, toGranularity: .month)
    }

    private func monthKey(_ month: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: month)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private func monthTitle(for month: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: month)
    }

    private func yearTitle(for month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: month)
    }

    private func weeks(for month: Date) -> [[MonthDay]] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlankDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = Date()
        let todayDay = calendar.isDate(month, equalTo: today, toGranularity: .month)
            ? calendar.component(.day, from: today)
            : -1

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var colorByDay: [Int: Color] = [:]
        for event in eventsByMonthKey[monthKey(month)] ?? [] {
            guard let date = dateFormatter.date(from: event.date),
                  calendar.isDate(date, equalTo: month, toGranularity: .month) else { continue }
            colorByDay[calendar.component(.day, from: date)] = colorForEvent(event)
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
    MonthlyView(
        legend: Array(MoilWatchSampleData.members.prefix(3)),
        colorForEvent: { _ in MoilWatchSampleData.members[0].color },
        loadEvents: { _ in [] }
    )
}
