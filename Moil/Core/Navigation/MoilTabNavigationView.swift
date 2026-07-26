import SwiftUI

struct MoilTabNavigationView: View {
    @State private var selectedTab: MoilTab = .calendar
    @State private var transitionEdge: Edge = .trailing
    @State private var isJoiningProfile = false
    @State private var isCreatingGroup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                if isJoiningProfile {
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
            .padding(.bottom, isJoiningProfile ? 0 : 72)

            if !isJoiningProfile {
                MoilTabBar(selected: selectedTab, onSelect: select)
                    .zIndex(10)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: selectedTab)
        .animation(.easeInOut(duration: 0.28), value: isJoiningProfile)
        .fullScreenCover(isPresented: $isCreatingGroup) {
            CreateGroupView()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .calendar:
            CalendarView(onTabSelect: select, showsTabBar: false)
        case .members:
            MemberView(onTabSelect: select, showsTabBar: false)
        case .create:
            GroupJoinCodeView(onNext: openJoinProfile, onTabSelect: select, showsTabBar: false)
        case .profile:
            MyPageView(onCreateGroup: { isCreatingGroup = true }, onTabSelect: select, showsTabBar: false)
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
        isJoiningProfile = false
        selectedTab = tab
    }

    private func openJoinProfile() {
        transitionEdge = .trailing
        isJoiningProfile = true
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
    MoilTabNavigationView()
        .environmentObject(MoilGroupStore())
}
