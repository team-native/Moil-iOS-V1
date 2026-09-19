import SwiftUI

/// 피그마 "Apple Watch · 가족" 화면입니다.
struct FamilyView: View {
    let members: [FamilyMember]
    let availability: [AvailabilitySlot]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("가족 일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                memberChips

                Text("오늘 가능한 시간")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchColor.textSecondary)

                ForEach(availability) { slot in
                    availabilityRow(slot)
                }
            }
        }
        .background(WatchColor.background)
    }

    private var memberChips: some View {
        HStack(spacing: 0) {
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                Text(member.initial)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WatchColor.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(member.color)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(WatchColor.background, lineWidth: 2)
                    }
                    .zIndex(Double(members.count - index))
                    .padding(.trailing, index == members.count - 1 ? 0 : -5)
            }
        }
    }

    private func availabilityRow(_ slot: AvailabilitySlot) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(slot.indicatorColor)
                .frame(width: 8, height: 8)
            Text(slot.timeRange)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchColor.textPrimary)
            Spacer(minLength: 0)
            Text(slot.summary)
                .font(.system(size: 9))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FamilyView(
        members: MoilWatchSampleData.members,
        availability: [
            AvailabilitySlot(id: "1", timeRange: "12:30–13:30", summary: "4명 모두", indicatorColor: MoilWatchSampleData.members[2].color),
            AvailabilitySlot(id: "2", timeRange: "17:00–18:00", summary: "3명 가능", indicatorColor: MoilWatchSampleData.members[1].color),
            AvailabilitySlot(id: "3", timeRange: "20:30 이후", summary: "4명 모두", indicatorColor: MoilWatchSampleData.members[3].color),
        ]
    )
}
