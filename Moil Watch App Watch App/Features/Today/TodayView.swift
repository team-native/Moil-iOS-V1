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
            LazyVStack(alignment: .leading, spacing: 8) {
                header
                    .padding(.bottom, 2)
                if let nextItem {
                    summaryCard(nextItem)
                }
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        WatchScheduleRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .onAppear { if item.id == items.last?.id { isLastItemVisible = true } }
                    .onDisappear { if item.id == items.last?.id { isLastItemVisible = false } }
                }
                if items.isEmpty {
                    WatchMessageView(systemImage: "sun.max", message: "오늘은 일정이 없어요")
                }
            }
            .padding(.horizontal, 4)
        }
        .background(WatchColor.background)
        .overlay(alignment: .bottom) {
            if items.count > 2 && !isLastItemVisible {
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 13, weight: .bold))
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
        HStack(alignment: .center, spacing: 8) {
            WatchScreenTitle(caption: "오늘 · \(dateTitle)", title: groupName)
            Spacer(minLength: 0)
            if let myProfile {
                WatchAvatar(member: myProfile, size: 30)
            }
        }
    }

    /// 다음 일정을 가장 먼저 보이게 합니다. 일정 주인의 대표색을 옅게 깔아 누구 일정인지 함께 보여줍니다.
    private func summaryCard(_ next: ScheduleItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("다음 일정 · \(next.time)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(next.owner.color)
            Text(next.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WatchColor.textPrimary)
                .lineLimit(2)
            Text("오늘 일정 \(items.count)개")
                .font(.system(size: 12))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(next.owner.color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
