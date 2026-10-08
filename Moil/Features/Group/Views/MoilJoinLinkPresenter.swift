import SwiftUI

/// 메인 화면 위에서 초대 링크(`moil://join/...`)와 푸시 알림 탭으로 들어온 그룹 전환을 처리합니다.
/// 이미 속한 그룹이면 그 그룹으로 전환하고, 아니면 초대 코드 → 프로필 설정 순서로 참여 화면을 띄웁니다.
struct MoilJoinLinkPresenter: ViewModifier {
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @State private var step: Step?

    private enum Step: Identifiable {
        case code(String?)
        case profile

        var id: String {
            switch self {
            case .code: "code"
            case .profile: "profile"
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .task(id: groupStore.pendingJoinLink) { await handlePendingLink() }
            .task(id: groupStore.pendingNotificationGroupId) { await handleNotificationGroup() }
            .fullScreenCover(item: $step) { step in
                switch step {
                case .code(let initialCode):
                    GroupJoinCodeView(onNext: {
                        self.step = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.step = .profile }
                    }, showsTabBar: false, initialCode: initialCode)
                case .profile:
                    GroupJoinProfileView { self.step = nil }
                }
            }
    }

    private func handleNotificationGroup() async {
        guard let groupId = groupStore.pendingNotificationGroupId, sessionStore.isAuthenticated else { return }
        groupStore.pendingNotificationGroupId = nil
        if !groupStore.groups.contains(where: { $0.id == groupId }) { try? await groupStore.load(using: sessionStore.service()) }
        groupStore.selectGroup(groupId)
    }

    private func handlePendingLink() async {
        guard let link = groupStore.pendingJoinLink, sessionStore.isAuthenticated else { return }
        groupStore.pendingJoinLink = nil
        // 콜드 스타트로 열린 경우 그룹 목록이 아직 비어 있을 수 있어, 이미 속한 그룹인지 먼저 확인합니다.
        if groupStore.groups.isEmpty { try? await groupStore.load(using: sessionStore.service()) }
        if let groupId = link.groupId, groupStore.groups.contains(where: { $0.id == groupId }) {
            groupStore.selectGroup(groupId)
            return
        }
        step = .code(link.inviteCode)
    }
}
