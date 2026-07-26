import SwiftUI

struct GroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLeavingGroup = false
    var onLeave: () -> Void = { }

    private let members: [(String, String, Color)] = [
        ("아빠", "관리자", MoilAvatarColor.blue),
        ("엄마", "멤버", MoilAvatarColor.red),
        ("나", "멤버", MoilAvatarColor.green),
        ("동생", "멤버", MoilAvatarColor.yellow)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 9, height: 16)
                    }
                    Text("우리 가족")
                        .font(MoilTypography.bold(22))
                }
                .foregroundStyle(MoilColor.groupDetailTextPrimary)
                .safeAreaPadding(.top, 22)

                Text("구성원")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .padding(.top, 17)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ForEach(members.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            MoilAvatar(color: members[index].2, size: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(members[index].0).font(MoilTypography.semibold(15))
                                Text(members[index].1)
                                    .font(MoilTypography.regular(12))
                                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 64)

                        if index < members.count - 1 {
                            Divider()
                                .overlay(MoilColor.groupDetailSeparator)
                                .padding(.leading, 60)
                        }
                    }
                }
                .foregroundStyle(MoilColor.groupDetailTextPrimary)
                .background(MoilColor.groupDetailSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("이번 달 일정")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .padding(.top, 15)
                    .padding(.bottom, 10)

                Text("7월 일정 5건")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.groupDetailTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MoilColor.groupDetailSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Button("그룹 나가기") { isLeavingGroup = true }
                    .font(MoilTypography.semibold(15))
                    .foregroundStyle(MoilColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(MoilColor.groupDetailBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .confirmationDialog("우리 가족 그룹을 나갈까요?", isPresented: $isLeavingGroup, titleVisibility: .visible) {
            Button("그룹 나가기", role: .destructive) {
                onLeave()
                dismiss()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("나가면 그룹의 일정과 멤버 정보를 더 이상 볼 수 없어요.")
        }
    }
}

#Preview("그룹 상세") {
    GroupDetailView()
}
