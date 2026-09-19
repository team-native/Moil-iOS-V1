import SwiftUI

/// 피그마 "Apple Watch · 가족" 화면입니다.
struct FamilyView: View {
    let groupName: String
    let members: [FamilyMember]
    /// 백엔드 API가 아직 없어 항상 빈 배열입니다. 연결되면 이 화면은 그대로 두고
    /// ContentView에서 실제 값을 채워 넣기만 하면 됩니다.
    let availability: [AvailabilitySlot]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(groupName)일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                memberChips

                if !availability.isEmpty {
                    Text("오늘 가능한 시간")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchColor.textSecondary)

                    ForEach(availability) { slot in
                        availabilityRow(slot)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(WatchColor.background)
    }

    /// 가족 수가 화면 너비보다 많아도 잘리지 않도록, 이 줄만 옆으로 스크롤할 수 있게 합니다.
    private var memberChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    Text(member.initial)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WatchColor.onAccent)
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
    FamilyView(groupName: "우리 가족", members: MoilWatchSampleData.members, availability: [])
}
