import SwiftUI

/// 워치 화면들이 같이 쓰는 프로필 원입니다. 사진이 있으면 사진을, 없으면 대표색 원 + 첫 글자를 보여줍니다.
struct WatchAvatar: View {
    let member: FamilyMember
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(member.color)
            Text(member.initial)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(WatchColor.onAccent)
            if let url = member.imageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(member.name)
    }
}

/// 오늘·다가오는 일정 목록의 한 줄입니다. 왼쪽 색 막대로 누구 일정인지 바로 보이게 합니다.
struct WatchScheduleRow: View {
    let item: ScheduleItem

    var body: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(item.owner.color)
                .frame(width: 4)
                .padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WatchColor.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(item.time)
                        .monospacedDigit()
                    if !item.owner.name.isEmpty {
                        Text("·")
                        Text(item.owner.name).lineLimit(1)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(WatchColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// 화면 위쪽 제목(작은 설명 + 큰 그룹 이름)입니다.
struct WatchScreenTitle: View {
    let caption: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WatchColor.textSecondary)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WatchColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// 일정이 없을 때나 오류가 났을 때 가운데에 보여주는 안내입니다.
struct WatchMessageView: View {
    let systemImage: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(WatchColor.textSecondary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(WatchColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
