import SwiftUI

struct MoilTabNavigationView: View {
    @EnvironmentObject private var groupStore: MoilGroupStore
    let onLogout: () -> Void
    @AppStorage("moilDarkMode") private var isDarkMode = false
    @State private var selectedTab: MoilTab = .calendar
    @State private var isJoiningProfile = false
    @State private var isCreatingGroup = false
    /// 마이페이지에서 계정 화면으로 들어가면 탭바를 숨겨야 하므로 상위에서 상태를 들고 있습니다.
    @State private var isAccountPagePresented = false

    var body: some View {
        ZStack {
            MoilColor.background
                .ignoresSafeArea()

            if isCreatingGroup {
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
            isTabBarVisible: !isJoiningProfile && !isCreatingGroup && !isAccountPagePresented,
            onSelect: select
        )
        .preferredColorScheme(isDarkMode ? .dark : .light)
        // 일정 알림을 탭하면 일정 상세를 띄우는 캘린더 탭으로 돌아옵니다.
        .task(id: groupStore.pendingNotificationEventId) {
            guard groupStore.pendingNotificationEventId != nil else { return }
            isCreatingGroup = false
            isJoiningProfile = false
            selectedTab = .calendar
        }
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
                isAccountPagePresented: $isAccountPagePresented
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
        .environmentObject(MoilSessionStore())
        .environmentObject(MoilEventStore())
}
