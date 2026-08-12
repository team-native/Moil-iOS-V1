import SwiftUI

enum MoilTab: Hashable {
    case calendar
    case members
    case create
    case profile
}

enum MoilTabBarStyle {
    case standard
    case dark

    var background: Color {
        switch self {
        case .standard: MoilColor.background
        case .dark: MoilColor.groupDetailBackground
        }
    }

    var unselectedColor: Color {
        switch self {
        case .standard: MoilColor.textSecondary
        case .dark: MoilColor.groupDetailTextSecondary
        }
    }

    var dividerColor: Color {
        switch self {
        case .standard: MoilColor.textTertiary.opacity(0.35)
        case .dark: MoilColor.groupDetailSeparator
        }
    }
}

struct MoilTabBar: View {
    let selected: MoilTab?
    var style: MoilTabBarStyle = .standard
    var onSelect: (MoilTab) -> Void

    var body: some View {
        HStack {
            item(.calendar, icon: "calendar")
            item(.members, icon: "person.2")
            item(.create, icon: "plus.circle")
            item(.profile, icon: "person")
        }
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(style.background)
        .overlay(alignment: .top) { Rectangle().fill(style.dividerColor).frame(height: 1).padding(.horizontal, 18) }
    }

    private func item(_ tab: MoilTab, icon: String) -> some View {
        Button { onSelect(tab) } label: {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(selected == tab ? MoilColor.primary : style.unselectedColor)
                .frame(maxWidth: .infinity, minHeight: 44)
                // 아이콘 글리프만이 아니라 칸 전체가 눌리도록 합니다.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: tab))
    }

    private func accessibilityLabel(for tab: MoilTab) -> String {
        switch tab {
        case .calendar: "캘린더"
        case .members: "멤버"
        case .create: "그룹 참여"
        case .profile: "마이페이지"
        }
    }
}

#Preview("하단 탭 바") {
    VStack { Spacer(); MoilTabBar(selected: .profile, onSelect: { _ in }) }
        .background(MoilColor.background)
}
