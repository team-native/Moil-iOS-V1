import SwiftUI

struct AuthFlowView: View {
    @AppStorage("moilDarkMode") private var isDarkMode = true
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
        // 토큰 재발급까지 실패해 세션이 끊기면 메인에 머물지 않고 로그인으로 돌아갑니다.
        .onChange(of: sessionStore.accessToken) { _, token in
            guard route == .main, token == nil else { return }
            groupStore.reset()
            eventStore.reset()
            route = .login
        }
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

                MoilTextField(placeholder: "이메일", text: $email, contentType: .emailAddress)
                    // 피그마: 이메일 칸 아래 12
                    .padding(.bottom, 12)

                MoilTextField(placeholder: "비밀번호", text: $password, isSecure: true, contentType: .password)
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
                MoilButton(title: "로그인", isEnabled: canSubmit && !isSubmitting) {
                    Task {
                        isSubmitting = true
                        errorMessage = await onLogin(email, password)
                        isSubmitting = false
                    }
                }

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
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding)
            .safeAreaPadding(.top, 40)
            .safeAreaPadding(.bottom, 34)
            .frame(maxWidth: 402)
        }
        .moilLoading(isSubmitting)
    }
}

private struct SignUpInfoView: View {
    let onBack: () -> Void
    let onNext: (String, String) async -> String?
    @State private var name = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var serverError: String?

    /// 입력하는 즉시 형식을 판단합니다.
    private var emailIsValid: Bool {
        email.range(of: #"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    private var canProceed: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && emailIsValid
    }

    private var emailState: MoilFieldState {
        guard !email.isEmpty else { return .neutral }
        return emailIsValid ? .success("올바른 형식이에요") : .failure("올바른 이메일 주소를 입력해주세요")
    }

    var body: some View {
        MoilAuthScaffold(title: "회원가입", onBack: onBack, isLoading: isSubmitting) {
            MoilFormStack {
                MoilValidatedField(label: "이름") {
                    MoilTextField(placeholder: "이름 입력", text: $name, contentType: .name)
                }
                MoilValidatedField(label: "이메일", state: emailState) {
                    MoilTextField(placeholder: "moil@example", text: $email, contentType: .emailAddress)
                }
            }
            .padding(.top, MoilTabScreenMetrics.fieldSpacing)

            if let serverError {
                Text(serverError)
                    .font(MoilTypography.regular(12))
                    .foregroundStyle(MoilColor.error)
                    .padding(.top, 8)
            }
        } bottom: {
            VStack(spacing: 0) {
                MoilAuthButton(title: "다음", isEnabled: canProceed && !isSubmitting) {
                    Task {
                        isSubmitting = true
                        serverError = await onNext(name, email)
                        isSubmitting = false
                    }
                }
                Button(action: onBack) {
                    Text("이미 계정이 있으신가요? ")
                        .foregroundStyle(MoilColor.textSecondary)
                    + Text("로그인")
                        .fontWeight(.bold)
                        .foregroundStyle(MoilColor.primary)
                }
                .font(MoilTypography.regular(14))
                .frame(maxWidth: .infinity)
                .padding(.top, 17)
            }
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
                MoilFormStack {
                    MoilValidatedField(label: "이메일") {
                        MoilTextField(placeholder: "moil@example", text: $email, contentType: .emailAddress)
                    }
                }
                .padding(.top, MoilTabScreenMetrics.fieldSpacing)
                if let serverError { Text(serverError).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 8) }
                Spacer()
                MoilButton(title: "인증번호 받기", isEnabled: email.contains("@") && !isSubmitting) {
                    Task { isSubmitting = true; serverError = await onNext(email); isSubmitting = false }
                }
                .safeAreaPadding(.bottom, 12)
            }
            .padding(.horizontal, MoilTabScreenMetrics.horizontalPadding).frame(maxWidth: 402)
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

    private var isComplete: Bool { code.count == 6 }

    /// 서버 오류가 있으면 그 문구를, 없으면 입력 진행 상태를 코드 칸 바로 아래에 보여 줍니다.
    private var codeState: MoilFieldState {
        if let serverError { return .failure(serverError) }
        guard !code.isEmpty else { return .neutral }
        return isComplete ? .success("인증번호가 확인되었어요") : .neutral
    }

    /// 피그마: 기본은 테두리 없음, 오류일 때 #CF4040, 완료되면 확인 색
    private func boxBorder(at index: Int) -> Color {
        if case .failure = codeState { return MoilColor.error }
        if isComplete { return MoilColor.success }
        return index == code.count && isCodeFieldFocused ? MoilColor.primary : .clear
    }

    var body: some View {
        MoilAuthScaffold(
            title: "이메일 인증",
            subtitle: "\(email)로 전송된\n인증번호 6자리를 입력해주세요",
            onBack: onBack,
            isLoading: isSubmitting
        ) {
            // 피그마: 코드 칸 위 16, 칸 52x55, 간격 8, 모서리 12
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        Text(code.character(at: index))
                            .font(MoilTypography.bold(19))
                            .foregroundStyle(MoilColor.textPrimary)
                        if index == code.count && isCodeFieldFocused {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(MoilColor.textPrimary)
                                .frame(width: 2, height: 24)
                                .opacity(isCaretVisible ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(width: 52, height: 55)
                    .background(MoilColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(boxBorder(at: index), lineWidth: 1) }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .contentShape(Rectangle())
            .onTapGesture { isCodeFieldFocused = true }
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
                // 다시 입력하면 이전 오류 문구를 지웁니다.
                serverError = nil
            }
            .onAppear {
                isCodeFieldFocused = true
                // 커서가 깜박이도록 반복 애니메이션을 겁니다.
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isCaretVisible = false
                }
            }

            // 피그마: 코드 칸 바로 아래에 상태 문구
            if let message = codeState.message {
                HStack(spacing: 6) {
                    if codeState.isSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(message).font(MoilTypography.bold(12))
                }
                .foregroundStyle(codeState.tint)
                .padding(.top, 10)
            }

            if !resendMessage.isEmpty {
                Text(resendMessage)
                    .font(MoilTypography.regular(12))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 8)
            }
        } bottom: {
            VStack(spacing: 0) {
                MoilAuthButton(title: "다음", isEnabled: isComplete && !isSubmitting) {
                    Task {
                        isSubmitting = true
                        serverError = await onNext(code)
                        isSubmitting = false
                    }
                }
                // 피그마: 버튼 아래 22, SemiBold 13
                Button("인증번호 재전송") { resendMessage = "인증번호를 다시 전송했어요" }
                    .font(MoilTypography.semibold(13))
                    .foregroundStyle(MoilColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
            }
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

    private var passwordState: MoilFieldState {
        guard !password.isEmpty else { return .neutral }
        return passwordIsValid ? .success("올바른 형식이에요") : .failure("비밀번호는 8자 이상이어야 해요")
    }

    private var confirmationState: MoilFieldState {
        guard !confirmation.isEmpty else { return .neutral }
        return passwordsMatch ? .success("비밀번호가 일치해요") : .failure("비밀번호가 올바르지 않아요")
    }

    var body: some View {
        MoilAuthScaffold(title: "비밀번호 설정", onBack: onBack, isLoading: isSubmitting) {
            MoilFormStack {
                MoilValidatedField(label: "비밀번호", state: passwordState) {
                    MoilTextField(placeholder: "비밀번호 입력", text: $password, isSecure: true, contentType: .newPassword)
                }
                MoilValidatedField(label: "비밀번호 확인", state: confirmationState) {
                    MoilTextField(placeholder: "비밀번호 재입력", text: $confirmation, isSecure: true, contentType: .newPassword)
                }
            }
            .padding(.top, MoilTabScreenMetrics.fieldSpacing)

            if let serverError {
                Text(serverError)
                    .font(MoilTypography.regular(12))
                    .foregroundStyle(MoilColor.error)
                    .padding(.top, 8)
            }
        } bottom: {
            VStack(spacing: 0) {
                MoilAuthButton(title: actionTitle, isEnabled: passwordIsValid && passwordsMatch && !isSubmitting) {
                    Task {
                        isSubmitting = true
                        serverError = await onComplete(password, confirmation)
                        isSubmitting = false
                    }
                }
                Button(action: onBack) {
                    Text("이미 계정이 있으신가요? ")
                        .foregroundStyle(MoilColor.textSecondary)
                    + Text("로그인")
                        .fontWeight(.bold)
                        .foregroundStyle(MoilColor.primary)
                }
                .font(MoilTypography.regular(14))
                .frame(maxWidth: .infinity)
                .padding(.top, 17)
            }
        }
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
