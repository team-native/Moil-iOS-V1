import SwiftUI

struct AuthFlowView: View {
    @AppStorage("moilDarkMode") private var isDarkMode = false
    @EnvironmentObject private var sessionStore: MoilSessionStore
    @EnvironmentObject private var groupStore: MoilGroupStore
    @EnvironmentObject private var eventStore: MoilEventStore
    @State private var route: AuthRoute = .restoring
    @State private var signUpName = ""
    @State private var signUpEmail = ""
    @State private var verifyId = ""
    @State private var signUpSessionId = ""
    @State private var resetEmail = ""
    @State private var resetSessionId = ""
    @State private var hasRestoredSession = false

    var body: some View {
        Group {
        switch route {
        case .restoring:
            MoilLaunchView()
        case .login:
            LoginView(showingSignUp: Binding(
                get: { route == .signUpInfo },
                set: { route = $0 ? .signUpInfo : .login }
            ), onLogin: login, onPasswordHelp: { route = .passwordResetEmail })
        case .signUpInfo:
            SignUpInfoView(
                onBack: { route = .login },
                onNext: { name, email in
                    signUpName = name
                    signUpEmail = email
                    return await requestSignUpCode(name: name, email: email)
                }
            )
        case .emailVerification:
            EmailVerificationView(
                email: signUpEmail,
                onBack: { route = .signUpInfo },
                onNext: verifySignUpCode
            )
        case .passwordSetup:
            PasswordSetupView(onBack: { route = .emailVerification }, onComplete: confirmSignUp)
        case .passwordResetEmail:
            PasswordResetEmailView(onBack: { route = .login }, onNext: requestResetCode)
        case .passwordResetVerification:
            EmailVerificationView(email: resetEmail, onBack: { route = .passwordResetEmail }, onNext: verifyResetCode)
        case .passwordResetSetup:
            PasswordSetupView(onBack: { route = .passwordResetVerification }, actionTitle: "비밀번호 변경", onComplete: resetPassword)
        case .main:
            MoilTabNavigationView(onLogout: logout)
        }
        }
        // 런치 화면과 auth 화면은 피그마에서 다크 한 가지로만 정의되어 있습니다.
        .preferredColorScheme(route == .main ? (isDarkMode ? .dark : .light) : .dark)
        .task { await restoreSession() }
    }

    private func login(email: String, password: String) async -> String? {
        do {
            let tokens = try await sessionStore.service().login(email: email, password: password)
            sessionStore.save(tokens)
            try await groupStore.load(using: sessionStore.service())
            route = .main
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func restoreSession() async {
        guard !hasRestoredSession else { return }
        hasRestoredSession = true
        guard sessionStore.hasStoredSession else {
            route = .login
            return
        }

        do {
            // 저장된 access token을 먼저 사용합니다. 요청이 401/403이면 공통 API 계층이
            // refresh token으로 한 번 재발급한 뒤 같은 요청을 재시도합니다.
            try await groupStore.load(using: sessionStore.service())
            route = .main
        } catch {
            if let apiError = error as? MoilAPIError, apiError.isAuthenticationFailure {
                sessionStore.clear()
                groupStore.reset()
                eventStore.reset()
                route = .login
            } else {
                // 자동 로그인 직후 일시적인 통신 실패는 로그인 해제로 취급하지 않습니다.
                route = .main
            }
        }
    }

    private func requestSignUpCode(name: String, email: String) async -> String? {
        do {
            let response = try await sessionStore.service().sendVerificationCode(name: name, email: email, step: .signUp)
            verifyId = response.verifyId
            route = .emailVerification
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func verifySignUpCode(_ code: String) async -> String? {
        do {
            let response = try await sessionStore.service().verifyCode(verifyId: verifyId, code: code)
            signUpSessionId = response.sessionId
            route = .passwordSetup
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func confirmSignUp(password: String, confirmation: String) async -> String? {
        do {
            let tokens = try await sessionStore.service().confirmSignUp(sessionId: signUpSessionId, password: password, confirmation: confirmation)
            sessionStore.save(tokens)
            try await groupStore.load(using: sessionStore.service())
            route = .main
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func requestResetCode(email: String) async -> String? {
        do {
            let response = try await sessionStore.service().sendVerificationCode(name: nil, email: email, step: .reset)
            resetEmail = email
            verifyId = response.verifyId
            route = .passwordResetVerification
            return nil
        } catch { return error.localizedDescription }
    }

    private func verifyResetCode(_ code: String) async -> String? {
        do {
            let response = try await sessionStore.service().verifyCode(verifyId: verifyId, code: code)
            resetSessionId = response.sessionId
            route = .passwordResetSetup
            return nil
        } catch { return error.localizedDescription }
    }

    private func resetPassword(password: String, confirmation: String) async -> String? {
        do {
            _ = try await sessionStore.service().resetPassword(sessionId: resetSessionId, password: password, confirmation: confirmation)
            route = .login
            return nil
        } catch { return error.localizedDescription }
    }

    private func logout() {
        Task {
            try? await sessionStore.service().logout()
            sessionStore.clear()
            groupStore.reset()
            eventStore.reset()
            route = .login
        }
    }
}

private enum AuthRoute {
    case restoring
    case login
    case signUpInfo
    case emailVerification
    case passwordSetup
    case passwordResetEmail
    case passwordResetVerification
    case passwordResetSetup
    case main
}

private struct LoginView: View {
    @Binding var showingSignUp: Bool
    let onLogin: (String, String) async -> String?
    let onPasswordHelp: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 8
    }

    var body: some View {
        ZStack {
            MoilColor.background
                .ignoresSafeArea()

            // 피그마: 컨테이너 좌우 24, 위 40, 아래 34
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // 피그마: 마스코트 76x76.34, 아래 10
                Image("MoilMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76.34)
                    .padding(.bottom, 10)

                // 피그마: 위 6 / 아래 2
                Text("모일")
                    .font(MoilTypography.bold(22))
                    .foregroundStyle(MoilColor.textPrimary)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                Text("각자의 시간이 모여, 우리의 약속이 되는 곳")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                    // 피그마: 로고 블록 아래 36
                    .padding(.bottom, 36)

                AuthTextField(title: "이메일", text: $email, contentType: .emailAddress)
                    // 피그마: 이메일 칸 아래 12
                    .padding(.bottom, 12)

                AuthTextField(title: "비밀번호", text: $password, isSecure: true, contentType: .password)
                    // 피그마: 비밀번호 블록 63, 칸 53
                    .padding(.bottom, 10)

                HStack {
                    Spacer(minLength: 0)
                    Button("비밀번호를 잊으셨나요?", action: onPasswordHelp)
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textSecondary)
                }
                .padding(.top, 4)
                .padding(.bottom, 2)

                Spacer(minLength: 0)

                SocialLoginRow { provider in
                    errorMessage = "\(provider) 로그인은 준비 중이에요."
                }
                // 피그마: 아이콘 아래 52에서 하단 블록 시작
                .padding(.bottom, 52)

                if let errorMessage {
                    Text(errorMessage)
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }

                // 피그마: 버튼 위 18 / 아래 17, 모서리 14
                Button("로그인") {
                    Task {
                        isSubmitting = true
                        errorMessage = await onLogin(email, password)
                        isSubmitting = false
                    }
                }
                .font(MoilTypography.bold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 17)
                .background(canSubmit ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(!canSubmit || isSubmitting)

                // 피그마: 버튼과 14 간격, 위 3 / 아래 2
                Button {
                    showingSignUp = true
                } label: {
                    Text("계정이 없으신가요? ")
                        .foregroundStyle(MoilColor.textSecondary)
                    + Text("회원가입")
                        .fontWeight(.bold)
                        .foregroundStyle(MoilColor.primary)
                }
                .font(MoilTypography.regular(14))
                .padding(.top, 17)
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 24)
            .safeAreaPadding(.top, 40)
            .safeAreaPadding(.bottom, 34)
            .frame(maxWidth: 402)
        }
    }
}

private struct SignUpInfoView: View {
    let onBack: () -> Void
    let onNext: (String, String) async -> String?
    @State private var name = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var serverError: String?

    private var emailIsValid: Bool {
        email.isEmpty || (email.contains("@") && email.contains("."))
    }

    private var canProceed: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !email.isEmpty && emailIsValid
    }

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("회원가입")
                        .font(MoilTypography.bold(28))
                        .foregroundStyle(MoilColor.textPrimary)
                        .safeAreaPadding(.top, 16)

                    Text("이름")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    AuthTextField(title: "이름 입력", text: $name, contentType: .name)

                    Text("이메일")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                    AuthTextField(title: "moil@example", text: $email, contentType: .emailAddress)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(emailIsValid ? .clear : MoilColor.error, lineWidth: 1)
                        }

                    if !emailIsValid {
                        Text("올바른 이메일 주소를 입력해주세요")
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilColor.error)
                            .padding(.top, 8)
                    }
                }

                Spacer()

                MoilPrimaryButton(title: "다음", isEnabled: canProceed, isLoading: isSubmitting) {
                    Task {
                        isSubmitting = true
                        serverError = await onNext(name, email)
                        isSubmitting = false
                    }
                }
                if let serverError {
                    Text(serverError).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 8)
                }

                Button(action: onBack) {
                    Text("이미 계정이 있으신가요? ")
                        .foregroundStyle(MoilColor.textSecondary)
                    + Text("로그인")
                        .fontWeight(.bold)
                        .foregroundStyle(MoilColor.primary)
                }
                .font(MoilTypography.regular(14))
                .padding(.top, 14)
                .safeAreaPadding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 402)
        }
    }
}

private struct PasswordResetEmailView: View {
    let onBack: () -> Void
    let onNext: (String) async -> String?
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var serverError: String?

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: onBack) { Image(systemName: "chevron.left").foregroundStyle(MoilColor.textPrimary) }
                    Text("비밀번호 재설정").font(MoilTypography.bold(26))
                }
                .safeAreaPadding(.top, 16)
                Text("가입한 이메일 주소로 인증번호를 보낼게요.")
                    .font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary).padding(.top, 12)
                AuthTextField(title: "moil@example", text: $email, contentType: .emailAddress).padding(.top, 24)
                if let serverError { Text(serverError).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 8) }
                Spacer()
                Button("인증번호 받기") {
                    Task { isSubmitting = true; serverError = await onNext(email); isSubmitting = false }
                }
                .font(MoilTypography.bold(16)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(email.contains("@") ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 14)).disabled(!email.contains("@") || isSubmitting)
                .safeAreaPadding(.bottom, 12)
            }
            .padding(.horizontal, 24).frame(maxWidth: 402)
        }
    }
}

private struct EmailVerificationView: View {
    let email: String
    let onBack: () -> Void
    let onNext: (String) async -> String?
    @State private var code = ""
    @State private var resendMessage = ""
    @State private var isSubmitting = false
    @State private var serverError: String?
    @FocusState private var isCodeFieldFocused: Bool
    @State private var isCaretVisible = true
    @State private var isEditingCode = true

    private var isComplete: Bool { code.count == 6 }

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                    }
                    Text("이메일 인증")
                        .font(MoilTypography.bold(26))
                        .foregroundStyle(MoilColor.textPrimary)
                }
                .safeAreaPadding(.top, 16)
                Text("\(email)로 전송된 인증번호 6자리를 입력해주세요")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 12)

                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        ZStack {
                            Text(code.character(at: index))
                                .font(MoilTypography.bold(19))
                            if index == code.count && isEditingCode {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .frame(width: 2, height: 24)
                                    .opacity(isCaretVisible ? 1 : 0.28)
                                    .accessibilityHidden(true)
                            }
                        }
                            .frame(width: 52, height: 52)
                            .background(MoilColor.surface)
                            .overlay { RoundedRectangle(cornerRadius: 12).stroke(index == code.count && !code.isEmpty ? MoilColor.error : .clear, lineWidth: 1) }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditingCode = true
                    isCodeFieldFocused = true
                }
                .background {
                    TextField("", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isCodeFieldFocused)
                        .opacity(0.001)
                        .frame(width: 1, height: 1)
                }
                .onChange(of: code) { _, value in
                    code = String(value.filter(\.isNumber).prefix(6))
                    isEditingCode = code.count < 6
                }
                .onAppear {
                    isEditingCode = true
                    isCodeFieldFocused = true
                    withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                        isCaretVisible = false
                    }
                }
                .padding(.top, 16)

                Button("인증번호 재전송") { resendMessage = "인증번호를 다시 전송했어요" }
                    .font(MoilTypography.semibold(13))
                    .foregroundStyle(MoilColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
                if !resendMessage.isEmpty {
                    Text(resendMessage)
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }

                Spacer()
                MoilPrimaryButton(title: "다음", isEnabled: isComplete, isLoading: isSubmitting) {
                    Task {
                        isSubmitting = true
                        serverError = await onNext(code)
                        isSubmitting = false
                    }
                }
                    .safeAreaPadding(.bottom, 12)
                if let serverError {
                    Text(serverError).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 402)
        }
    }
}

private extension String {
    func character(at index: Int) -> String {
        guard index < count else { return "" }
        return String(self[self.index(startIndex, offsetBy: index)])
    }
}

private struct PasswordSetupView: View {
    let onBack: () -> Void
    var actionTitle = "가입하기"
    let onComplete: (String, String) async -> String?
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSubmitting = false
    @State private var serverError: String?

    private var passwordIsValid: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { !confirmation.isEmpty && password == confirmation }

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                    }
                    Text("비밀번호 설정")
                        .font(MoilTypography.bold(26))
                        .foregroundStyle(MoilColor.textPrimary)
                }
                .safeAreaPadding(.top, 16)
                Text("비밀번호")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.textTertiary)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                AuthTextField(title: "비밀번호 입력", text: $password, isSecure: true, contentType: .newPassword)
                if !password.isEmpty && !passwordIsValid {
                    Text("비밀번호는 8자 이상이어야 해요")
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.error)
                        .padding(.top, 8)
                }
                Text("비밀번호 확인")
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.textTertiary)
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                AuthTextField(title: "비밀번호 재입력", text: $confirmation, isSecure: true, contentType: .newPassword)
                if !confirmation.isEmpty && !passwordsMatch {
                    Text("비밀번호가 일치하지 않아요")
                        .font(MoilTypography.regular(12))
                        .foregroundStyle(MoilColor.error)
                        .padding(.top, 8)
                }
                Spacer()
                Button(actionTitle) {
                    Task {
                        isSubmitting = true
                        serverError = await onComplete(password, confirmation)
                        isSubmitting = false
                    }
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(passwordIsValid && passwordsMatch ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!(passwordIsValid && passwordsMatch))
                    .safeAreaPadding(.bottom, 12)
                if let serverError {
                    Text(serverError).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 402)
        }
    }
}

private struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var isSecure = false
    var contentType: UITextContentType?
    var placeholderColor: Color = MoilColor.fieldPlaceholder
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .font(MoilTypography.regular(15))
                        .foregroundStyle(placeholderColor)
                }
                Group {
                    if isSecure && !isRevealed {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(MoilTypography.regular(15))
                .foregroundStyle(MoilColor.textPrimary)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }

            if isSecure {
                Button { isRevealed.toggle() } label: {
                    Image(systemName: isRevealed ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(placeholderColor)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel(isRevealed ? "비밀번호 숨기기" : "비밀번호 표시")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 53)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoilColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// 피그마 로그인 화면의 간편 로그인 영역입니다. 연동 전까지는 안내만 띄웁니다.
/// 구분선과 아이콘 위치는 피그마 좌표를 그대로 씁니다.
private struct SocialLoginRow: View {
    let onSelect: (String) -> Void

    /// 피그마: 구분선 125x1, 좌측 x30 / 우측 x247, 텍스트와 각각 14 간격
    private let dividerWidth: CGFloat = 125
    /// 피그마: 아이콘 중심 x 97 / 201 / 303 → 간격 102, 아이콘 상자 38
    private let iconBoxSize: CGFloat = 38
    private let iconGap: CGFloat = 102 - 38

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                divider
                Text("간편 로그인")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .fixedSize()
                divider
            }
            .padding(.horizontal, -6)

            HStack(spacing: iconGap) {
                socialButton("구글") {
                    Image("SocialGoogle").resizable().scaledToFit().frame(width: 34, height: 34)
                }
                socialButton("애플") {
                    // 피그마 벡터는 흰 글리프여서 라이트 모드에서 보이지 않습니다. 같은 모양의 시스템 아이콘을 씁니다.
                    Image(systemName: "apple.logo")
                        .font(.system(size: 30))
                        .foregroundStyle(MoilColor.textPrimary)
                }
                socialButton("카카오") {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.898, blue: 0.0))
                        .frame(width: 38, height: 38)
                        .overlay {
                            Image("SocialKakao").resizable().scaledToFit().frame(width: 22, height: 20.7)
                        }
                }
            }
            .padding(.top, 39)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(MoilColor.textTertiary.opacity(0.34))
            .frame(width: dividerWidth, height: 1)
    }

    private func socialButton<Icon: View>(_ name: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button { onSelect(name) } label: {
            icon().frame(width: iconBoxSize, height: iconBoxSize)
        }
        .accessibilityLabel("\(name)로 로그인")
    }
}

#Preview {
    AuthFlowView()
}
