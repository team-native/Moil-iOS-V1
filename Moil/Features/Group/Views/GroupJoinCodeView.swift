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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if showsTabBar {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary).frame(width: 32, height: 32)
                    }
                }
                Text("그룹 참여").font(MoilTypography.bold(26))
                Spacer()
            }
            .safeAreaPadding(.top, MoilTabScreenMetrics.topPadding)
            Text("초대 코드를 입력해주세요").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary).padding(.top, 8)
            Text("초대 코드").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 30).padding(.bottom, 10)
            TextField("FAM-0000", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(MoilTypography.bold(15)).tracking(1)
                .padding(.horizontal, 17).frame(height: 56)
                .background(MoilColor.surface).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(error == nil ? Color.clear : MoilColor.error, lineWidth: 1) }
                .onChange(of: code) { _, value in
                    let normalized = String(value.uppercased().prefix(8))
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
                            let verification = try await sessionStore.service().verifyInviteCode(code)
                            groupStore.pendingInviteCode = code
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
            .disabled(code.isEmpty)
            .safeAreaPadding(.bottom, 12)
        }
        .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
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
