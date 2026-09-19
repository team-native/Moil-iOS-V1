import SwiftUI

/// 피그마 "Apple Watch · 가족" 화면입니다.
struct FamilyView: View {
    let members: [FamilyMember]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("가족 일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                memberChips

                ForEach(members) { member in
                    memberRow(member)
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

    private func memberRow(_ member: FamilyMember) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(member.color)
                .frame(width: 8, height: 8)
            Text(member.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FamilyView(members: MoilWatchSampleData.members)
}
