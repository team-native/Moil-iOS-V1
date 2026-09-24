import SwiftUI

/// 내일부터 7일 안의 하루치 일정 묶음입니다.
struct UpcomingDay: Identifiable {
    let id: String
    let label: String
    let items: [ScheduleItem]
}

/// 첫 번째 탭: 오늘 탭(오늘만)과 캘린더 탭(월 단위) 사이를 채우는 "다가오는 일정" 화면입니다.
struct UpcomingView: View {
    let groupName: String
    let days: [UpcomingDay]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("다가오는 일정")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchColor.textSecondary)
                    Text(groupName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(WatchColor.textPrimary)
                }

                if days.isEmpty {
                    Text("앞으로 7일간 일정이 없어요")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchColor.textSecondary)
                        .padding(.top, 8)
                } else {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(WatchColor.textSecondary)
                            ForEach(day.items) { item in
                                scheduleRow(item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(WatchColor.background)
    }

    private func scheduleRow(_ item: ScheduleItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.owner.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.time)
                    .font(.system(size: 9))
                    .foregroundStyle(WatchColor.textSecondary)
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchColor.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    UpcomingView(
        groupName: "우리 가족",
        days: [
            UpcomingDay(id: "1", label: "내일", items: [
                ScheduleItem(id: "1", time: "14:00", title: "아빠 골프", owner: MoilWatchSampleData.members[1]),
            ]),
            UpcomingDay(id: "2", label: "토 · 9/26", items: [
                ScheduleItem(id: "2", time: "18:30", title: "가족 저녁", owner: MoilWatchSampleData.members[0]),
                ScheduleItem(id: "3", time: "종일", title: "이사", owner: MoilWatchSampleData.members[2]),
            ]),
        ]
    )
}
