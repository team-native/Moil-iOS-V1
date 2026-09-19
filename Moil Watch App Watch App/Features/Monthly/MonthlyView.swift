import SwiftUI
import WatchKit

/// 피그마 "Apple Watch · 월간" 화면입니다.
/// 아이폰 앱(CalendarView)과 동일하게, 달을 하나씩 넘기는 대신 여러 달을 이어붙여
/// 아래로 계속 스크롤할 수 있게 합니다. LazyVStack이라 화면 근처 달만 실제로 그려지고,
/// 각 달의 일정은 화면에 걸릴 때 그 달만 따로 불러옵니다.
struct MonthlyView: View {
    let colorForEvent: (MoilRemoteEvent) -> Color
    let loadEvents: (Date) async -> [MoilRemoteEvent]

    @Environment(\.scenePhase) private var scenePhase
    @State private var monthsWindow: [Date] = MonthlyView.makeMonthsWindow()
    @State private var scrollPositionMonth: Date?
    @State private var eventsByMonthKey: [String: [MoilRemoteEvent]] = [:]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    private let weekdayHeaderHeight: CGFloat = 15

    /// 스크롤 방식은 그대로 두고, 한 달(최대 6주)이 스크롤 없이 화면 안에 통째로
    /// 들어오도록 칸 크기를 화면 폭/높이 둘 다에 맞춰 계산합니다. 요일 줄(고정)과 매
    /// 달 제목 줄이 차지하는 만큼을 뺀 나머지를 6주로 나눈 값과, 화면 폭을 7로 나눈
    /// 값 중 작은 쪽을 씁니다. 워치마다 화면 크기가 달라 값도 자동으로 맞춰집니다.
    private var gridCellSize: CGFloat {
        let bounds = WKInterfaceDevice.current().screenBounds
        let widthBudget = bounds.width / 7
        let topInset: CGFloat = 6 // 요일 줄이 화면 모서리 곡선에 안 잘리게 두는 여유
        let perMonthTitleHeight: CGFloat = 30
        let weekRowSpacing: CGFloat = 2 * 5
        // 페이지 인디케이터(점)가 화면 맨 아래에 겹쳐 그려져 마지막 주가 가려지므로 여유를 더 둡니다.
        let pageIndicatorMargin: CGFloat = 22
        let heightBudget = max(
            18,
            (bounds.height - topInset - weekdayHeaderHeight - perMonthTitleHeight - weekRowSpacing - pageIndicatorMargin) / 6
        )
        return min(widthBudget, heightBudget)
    }

    private static func makeMonthsWindow() -> [Date] {
        let calendar = Calendar.current
        let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return (-180...180).compactMap { calendar.date(byAdding: .month, value: $0, to: firstOfThisMonth) }
    }

    var body: some View {
        VStack(spacing: 2) {
            weekdayHeader
                .padding(.top, 6)
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
        }
        .onAppear {
            guard scrollPositionMonth == nil else { return }
            let today = Date()
            scrollPositionMonth = monthsWindow.first { calendar.isDate($0, equalTo: today, toGranularity: .month) }
        }
        // 이미 불러온 달은 다시 요청하지 않게 캐시해 두는데, 그러면 아이폰에서 새로
        // 추가한 일정이 워치를 다시 열어도 안 보일 수 있어 화면이 다시 활성화될 때마다
        // 캐시를 비워 화면에 걸린 달들이 새로 로딩되게 합니다.
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            eventsByMonthKey = [:]
        }
        .background(WatchColor.background)
    }

    @ViewBuilder
    private func monthSection(for month: Date) -> some View {
        let isFirst = isFirstMonth(month)
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(monthTitle(for: month))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)
                Text(yearTitle(for: month))
                    .font(.system(size: 9))
                    .foregroundStyle(WatchColor.textSecondary)
            }
            .padding(.top, isFirst ? 0 : 10)

            VStack(spacing: 2) {
                ForEach(Array(weeks(for: month).enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(week) { dayCell($0) }
                    }
                }
            }
        }
        .task(id: monthKey(month)) {
            guard eventsByMonthKey[monthKey(month)] == nil else { return }
            eventsByMonthKey[monthKey(month)] = await loadEvents(month)
        }
    }

    /// 달마다 반복해서 그릴 필요가 없어 스크롤 영역 위에 한 번만 고정해 둡니다.
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 8))
                    .foregroundStyle(WatchColor.textSecondary)
                    .frame(width: gridCellSize, height: weekdayHeaderHeight)
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
        .frame(width: gridCellSize, height: gridCellSize)
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
        colorForEvent: { _ in MoilWatchSampleData.members[0].color },
        loadEvents: { _ in [] }
    )
}
