import SwiftUI

struct GroupJoinCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var sessionStore: MoilSessionStore
    let onNext: () -> Void
    let onTabSelect: ((MoilTab) -> Void)?
    let showsTabBar: Bool
    @State private var code = ""
    @State private var error: String?
    @State private var isVerified = false
    @State private var isVerifying = false

    init(onNext: @escaping () -> Void = {}, onTabSelect: ((MoilTab) -> Void)? = nil, showsTabBar: Bool = true) {
        self.onNext = onNext
        self.onTabSelect = onTabSelect
        self.showsTabBar = showsTabBar
    }

    private var backAction: (() -> Void)? {
        guard showsTabBar else { return nil }
        return { dismiss() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoilScreenHeader(title: "그룹 참여", subtitle: "초대 코드를 입력해주세요", onBack: backAction)
            VStack(alignment: .leading, spacing: 0) {
            Text("초대 코드").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.bottom, 10)
            TextField("FAM-0000", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .tracking(1)
                .moilField()
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(error == nil ? Color.clear : MoilColor.error, lineWidth: 1) }
                .onChange(of: code) { _, value in
                    let normalized = String(value.uppercased().prefix(64))
                    if normalized != value { code = normalized }
                    error = nil
                    isVerified = false
                }
            if let error { Text(error).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 6) }
            if isVerified {
                HStack(spacing: 10) { MoilAvatar(color: MoilAvatarColor.green, size: 30); Text("\(groupStore.pendingInviteGroupName)에 참여할 준비가 됐어요") .font(MoilTypography.semibold(14)) }
                    .padding(.top, 16)
            }
            Spacer()
            Button(isVerified ? "다음" : "확인") {
                if isVerified { onNext() }
                else {
                    Task {
                        isVerifying = true
                        do {
                            let inviteCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
                            let verification = try await sessionStore.service().verifyInviteCode(inviteCode)
                            groupStore.pendingInviteCode = verification.inviteCode
                            groupStore.pendingInviteGroupName = verification.groupName
                            groupStore.pendingInviteMemberCount = verification.memberCount
                            isVerified = true
                        } catch let requestError {
                            error = requestError.localizedDescription
                        }
                        isVerifying = false
                    }
                }
            }
            .font(MoilTypography.bold(16)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(code.isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifying)
            .safeAreaPadding(.bottom, 12)
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
        }
        .background(MoilColor.background.ignoresSafeArea())
        .moilTabScreenLayout(selected: .create, isTabBarVisible: showsTabBar) { tab in
            if let onTabSelect {
                onTabSelect(tab)
            } else if tab != .create {
                dismiss()
            }
        }
    }
}

#Preview("그룹 참여 코드") {
    GroupJoinCodeView()
}
