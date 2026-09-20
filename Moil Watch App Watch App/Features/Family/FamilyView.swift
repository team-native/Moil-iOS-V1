import SwiftUI

/// 피그마 "Apple Watch · 가족" 화면입니다.
struct FamilyView: View {
    let groupName: String
    let members: [FamilyMember]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(groupName)일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                memberChips
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
}

#Preview {
    FamilyView(groupName: "우리 가족", members: MoilWatchSampleData.members)
}
