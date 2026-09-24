import SwiftUI

/// 피그마 "Apple Watch · 오늘" 화면입니다.
struct TodayView: View {
    let groupName: String
    let dateTitle: String
    let items: [ScheduleItem]
    let myProfile: FamilyMember?
    let onSelect: (ScheduleItem) -> Void

    private var nextItem: ScheduleItem? { items.first }

    /// 마지막 일정 카드가 화면에 보이는지입니다. LazyVStack은 화면에 들어올 때만 onAppear가
    /// 불려서, 마지막 카드가 아직 안 보이면 "아래에 일정이 더 있음"으로 판단합니다.
    @State private var isLastItemVisible = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                header
                if let nextItem {
                    summaryCard(nextItem)
                }
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        scheduleRow(item)
                    }
                    .buttonStyle(.plain)
                    .onAppear { if item.id == items.last?.id { isLastItemVisible = true } }
                    .onDisappear { if item.id == items.last?.id { isLastItemVisible = false } }
                }
                if items.isEmpty {
                    Text("오늘은 일정이 없어요")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchColor.textSecondary)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(WatchColor.background)
        .overlay(alignment: .bottom) {
            if items.count > 1 && !isLastItemVisible {
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(WatchColor.surface)
                    .clipShape(Capsule())
                    .padding(.bottom, 2)
                    .allowsHitTesting(false)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("오늘 · \(dateTitle)")
                    .font(.system(size: 11))
                    .foregroundStyle(WatchColor.textSecondary)
                Text(groupName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)
            }
            Spacer(minLength: 0)
            profileCircle
        }
    }

    @ViewBuilder
    private var profileCircle: some View {
        if let myProfile {
            Text(myProfile.initial)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchColor.onAccent)
                .frame(width: 28, height: 28)
                .background(myProfile.color)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(WatchColor.surface)
                .frame(width: 28, height: 28)
        }
    }

    private func summaryCard(_ next: ScheduleItem) -> some View {
        HStack(spacing: 6) {
            Text("\(items.count)개 일정")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WatchColor.textPrimary)
            Text("다음 약속 \(next.time)")
                .font(.system(size: 9))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    TodayView(
        groupName: "우리 가족",
        dateTitle: "7월 22일",
        items: [
            ScheduleItem(id: "1", time: "14:00", title: "아빠 골프", owner: MoilWatchSampleData.members[1]),
            ScheduleItem(id: "2", time: "18:30", title: "나 팀 회의", owner: MoilWatchSampleData.members[2]),
            ScheduleItem(id: "3", time: "20:00", title: "저녁 약속", owner: MoilWatchSampleData.members[0]),
        ],
        myProfile: MoilWatchSampleData.members[2],
        onSelect: { _ in }
    )
}
