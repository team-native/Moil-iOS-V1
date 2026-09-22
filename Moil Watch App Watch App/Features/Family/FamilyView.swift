import SwiftUI

/// 피그마 "Apple Watch · 가족" 화면입니다.
struct FamilyView: View {
    let groupName: String
    let members: [FamilyMember]
    /// 오늘 가장 가까운 일정 기준으로 가족이 등록한 가능 시간대입니다(읽기 전용).
    /// 오늘 일정이 없거나 아직 아무도 등록하지 않았으면 nil입니다.
    let availability: MoilAvailabilitySummary?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(groupName)일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                memberChips

                if let availability, !availability.timeSlots.isEmpty {
                    Text("오늘 가능한 시간")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchColor.textSecondary)

                    ForEach(availability.timeSlots) { slot in
                        availabilityRow(slot)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(WatchColor.background)
    }

    /// 가족 수가 화면 너비보다 많아도 잘리지 않도록, 이 줄만 옆으로 스크롤할 수 있게 합니다.
    /// 세로 ScrollView 안에 가로 ScrollView가 중첩돼 있으면 watchOS가 디지털 크라운
    /// 입력을 어느 스크롤뷰로 보낼지 헷갈려 해서, 화면을 만지기도 전에 크라운만 돌려도
    /// 이 줄이 옆으로 밀려 보이는 문제가 있었습니다. 이 줄은 크라운 포커스를 받지 않게
    /// 막아 크라운은 항상 바깥 세로 스크롤만 움직이게 합니다(가로 스크롤은 손가락으로는 그대로 됨).
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
        .focusable(false)
    }

    private func availabilityRow(_ slot: MoilAvailabilitySummarySlot) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(slot.isAvailableForEveryone ? Color("MemberGreen") : WatchColor.textSecondary)
                .frame(width: 8, height: 8)
            Text("\(slot.startTime)–\(slot.endTime)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchColor.textPrimary)
            Spacer(minLength: 0)
            Text(slot.isAvailableForEveryone ? "모두 가능" : "\(slot.availableCount)명 가능")
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
    FamilyView(groupName: "우리 가족", members: MoilWatchSampleData.members, availability: nil)
}
