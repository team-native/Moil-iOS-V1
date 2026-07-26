import SwiftUI

enum MoilTab: Hashable {
    case calendar
    case members
    case create
    case profile
}

struct MoilTabBar: View {
    let selected: MoilTab?
    var onSelect: (MoilTab) -> Void

    var body: some View {
        HStack {
            item(.calendar, icon: "calendar")
            item(.members, icon: "person.2")
            item(.create, icon: "plus.circle")
            item(.profile, icon: "person")
        }
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(MoilColor.background)
        .overlay(alignment: .top) { Divider().padding(.horizontal, 18) }
    }

    private func item(_ tab: MoilTab, icon: String) -> some View {
        Button { onSelect(tab) } label: {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .regular))
                .frame(maxWidth: .infinity)
                .foregroundStyle(selected == tab ? MoilColor.primary : MoilColor.textTertiary)
        }
        .accessibilityLabel(accessibilityLabel(for: tab))
    }

    private func accessibilityLabel(for tab: MoilTab) -> String {
        switch tab {
        case .calendar: "캘린더"
        case .members: "멤버"
        case .create: "일정 추가"
        case .profile: "마이페이지"
        }
    }
}

#Preview("하단 탭 바") {
    VStack { Spacer(); MoilTabBar(selected: .profile, onSelect: { _ in }) }
        .background(MoilColor.background)
}
