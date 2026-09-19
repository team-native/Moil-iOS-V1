import SwiftUI

/// 피그마 "Apple Watch · 월간" 화면입니다.
struct MonthlyView: View {
    let monthTitle: String
    let yearTitle: String
    let weekdaySymbols: [String]
    /// 7일씩 묶은 주 단위 배열입니다. 월 앞뒤의 빈 칸은 day == nil로 채웁니다.
    let weeks: [[MonthDay]]
    let legend: [FamilyMember]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(monthTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(WatchColor.textPrimary)
                    Text(yearTitle)
                        .font(.system(size: 10))
                        .foregroundStyle(WatchColor.textSecondary)
                }

                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 8))
                            .foregroundStyle(WatchColor.textSecondary)
                            .frame(width: 25, height: 12)
                    }
                }

                VStack(spacing: 3) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        HStack(spacing: 0) {
                            ForEach(week) { dayCell($0) }
                        }
                    }
                }

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
        }
        .background(WatchColor.background)
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
        .frame(width: 25, height: 26)
        .background(day.isToday ? Color("MemberRed") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    let calendar = Calendar(identifier: .gregorian)
    let sampleWeeks: [[MonthDay]] = [
        [1, 2, 3, 4, 5, 6, 7].map { MonthDay(id: $0, day: $0, isToday: false, eventColor: $0 == 5 ? MoilWatchSampleData.members[2].color : nil) },
        (8...14).map { MonthDay(id: $0, day: $0, isToday: false, eventColor: nil) },
        (15...21).map { MonthDay(id: $0, day: $0, isToday: false, eventColor: $0 == 16 ? MoilWatchSampleData.members[1].color : nil) },
        (22...28).map { MonthDay(id: $0, day: $0, isToday: $0 == 22, eventColor: $0 == 22 || $0 == 28 ? MoilWatchSampleData.members[0].color : nil) },
        [29, 30, 31, -1, -2, -3, -4].map { MonthDay(id: $0, day: $0 > 0 ? $0 : nil, isToday: false, eventColor: nil) },
    ]
    _ = calendar
    return MonthlyView(
        monthTitle: "7월",
        yearTitle: "2026",
        weekdaySymbols: ["일", "월", "화", "수", "목", "금", "토"],
        weeks: sampleWeeks,
        legend: Array(MoilWatchSampleData.members.prefix(3))
    )
}
