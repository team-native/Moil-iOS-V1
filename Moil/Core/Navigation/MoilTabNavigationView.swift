import SwiftUI

struct MoilTabNavigationView: View {
    let onLogout: () -> Void
    @State private var selectedTab: MoilTab = .calendar
    @State private var isJoiningProfile = false
    @State private var isCreatingGroup = false
    /// 계정 화면은 탭 콘텐츠를 통째로 대체합니다. 하위에서 상태를 바꾸면
    /// 상위가 다시 그려지면서 화면 이동이 사라지기 때문입니다.
    @State private var accountRoute: MoilAccountRoute?

    var body: some View {
        ZStack {
            MoilColor.background
                .ignoresSafeArea()

            if let accountRoute {
                MoilAccountPage(route: accountRoute, onClose: { self.accountRoute = nil }, onLogout: onLogout)
            } else if isCreatingGroup {
                CreateGroupView(onClose: closeCreateGroup)
            } else if isJoiningProfile {
                GroupJoinProfileView {
                    isJoiningProfile = false
                    selectedTab = .calendar
                }
            } else {
                tabContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .moilTabScreenLayout(
            selected: selectedTab,
            isTabBarVisible: !isJoiningProfile && !isCreatingGroup && accountRoute == nil,
            onSelect: select
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .calendar:
            CalendarView(onTabSelect: select, onCreateGroup: openCreateGroup, showsTabBar: false)
        case .members:
            MemberView(onTabSelect: select, onCreateGroup: openCreateGroup, showsTabBar: false)
        case .create:
            GroupJoinCodeView(onNext: openJoinProfile, onTabSelect: select, showsTabBar: false)
        case .profile:
            MyPageView(
                onCreateGroup: openCreateGroup,
                onLogout: onLogout,
                onTabSelect: select,
                showsTabBar: false,
                onAccountRoute: { accountRoute = $0 }
            )
        }
    }

    private func select(_ tab: MoilTab) {
        guard tab != selectedTab || isJoiningProfile else { return }
        isJoiningProfile = false
        selectedTab = tab
    }

    private func openJoinProfile() {
        isJoiningProfile = true
    }

    private func openCreateGroup() {
        isCreatingGroup = true
    }

    private func closeCreateGroup() {
        isCreatingGroup = false
    }
}

#Preview("공통 탭 네비게이션") {
    MoilTabNavigationView(onLogout: {})
        .environmentObject(MoilGroupStore())
}
