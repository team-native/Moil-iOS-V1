import SwiftUI

struct MoilTabNavigationView: View {
    let onLogout: () -> Void
    @State private var selectedTab: MoilTab = .calendar
    @State private var transitionEdge: Edge = .trailing
    @State private var isJoiningProfile = false
    @State private var isCreatingGroup = false

    var body: some View {
        ZStack {
            MoilColor.background
                .ignoresSafeArea()

            if isCreatingGroup {
                CreateGroupView(onClose: closeCreateGroup)
                    .transition(contentTransition)
            } else if isJoiningProfile {
                GroupJoinProfileView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        isJoiningProfile = false
                        selectedTab = .calendar
                    }
                }
                .transition(contentTransition)
            } else {
                tabContent
                    .id(selectedTab)
                    .transition(contentTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .moilTabScreenLayout(
            selected: selectedTab,
            isTabBarVisible: !isJoiningProfile && !isCreatingGroup,
            onSelect: select
        )
        .animation(.easeInOut(duration: 0.28), value: isJoiningProfile)
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
            MyPageView(onCreateGroup: openCreateGroup, onLogout: onLogout, onTabSelect: select, showsTabBar: false)
        }
    }

    private var contentTransition: AnyTransition {
        let opposite: Edge = transitionEdge == .trailing ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: transitionEdge).combined(with: .opacity),
            removal: .move(edge: opposite).combined(with: .opacity)
        )
    }

    private func select(_ tab: MoilTab) {
        guard tab != selectedTab || isJoiningProfile else { return }
        transitionEdge = tabIndex(for: tab) > tabIndex(for: selectedTab) ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.28)) {
            isJoiningProfile = false
            selectedTab = tab
        }
    }

    private func openJoinProfile() {
        transitionEdge = .trailing
        isJoiningProfile = true
    }

    private func openCreateGroup() {
        transitionEdge = .trailing
        withAnimation(.easeInOut(duration: 0.28)) {
            isCreatingGroup = true
        }
    }

    private func closeCreateGroup() {
        transitionEdge = .leading
        withAnimation(.easeInOut(duration: 0.28)) {
            isCreatingGroup = false
        }
    }

    private func tabIndex(for tab: MoilTab) -> Int {
        switch tab {
        case .calendar: 0
        case .members: 1
        case .create: 2
        case .profile: 3
        }
    }
}

#Preview("공통 탭 네비게이션") {
    MoilTabNavigationView(onLogout: {})
        .environmentObject(MoilGroupStore())
}
