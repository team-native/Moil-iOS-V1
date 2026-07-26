import SwiftUI

struct AuthFlowView: View {
    @State private var route: AuthRoute = .login

    var body: some View {
        switch route {
        case .login:
            LoginView(showingSignUp: Binding(
                get: { route == .signUpInfo },
                set: { route = $0 ? .signUpInfo : .login }
            ), onLogin: { route = .calendar })
        case .signUpInfo:
            SignUpInfoView(onBack: { route = .login }, onNext: { route = .emailVerification })
        case .emailVerification:
            EmailVerificationView(onBack: { route = .signUpInfo }, onNext: { route = .passwordSetup })
        case .passwordSetup:
            PasswordSetupView(onBack: { route = .emailVerification }, onComplete: { route = .login })
        case .calendar:
            CalendarView()
        }
    }
}

private enum AuthRoute {
    case login
    case signUpInfo
    case emailVerification
    case passwordSetup
    case calendar
}

private struct LoginView: View {
    @Binding var showingSignUp: Bool
    let onLogin: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordHelpPresented = false

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 8
    }

    var body: some View {
        ZStack {
            MoilColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Image("MoilMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 74)
                        Text("모일")
                            .font(MoilTypography.bold(22))
                            .foregroundStyle(MoilColor.textPrimary)
                        Text("각자의 시간이 모여, 우리의 약속이 되는 곳")
                            .font(MoilTypography.regular(13))
                            .foregroundStyle(MoilColor.textSecondary)
                    }
                    .padding(.bottom, 36)

                    VStack(spacing: 12) {
                        AuthTextField(title: "이메일", text: $email, contentType: .emailAddress)
                        AuthTextField(title: "비밀번호", text: $password, isSecure: true, contentType: .password)
                        HStack {
                            Spacer()
                            Button("비밀번호를 잊으셨나요?") { isPasswordHelpPresented = true }
                                .font(MoilTypography.regular(13))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)

                VStack(spacing: 14) {
                        Button("로그인", action: onLogin)
                            .font(MoilTypography.bold(16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(canSubmit ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(!canSubmit)

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
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("비밀번호 재설정", isPresented: $isPasswordHelpPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("가입한 이메일 주소로 비밀번호 재설정 안내를 보내드릴게요.")
        }
    }
}

private struct SignUpInfoView: View {
    let onBack: () -> Void
    let onNext: () -> Void
    @State private var name = ""
    @State private var email = ""

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
                        .padding(.top, 76)

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

                Button("다음", action: onNext)
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canProceed ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!canProceed)

                Button(action: onBack) {
                    Text("이미 계정이 있으신가요? ")
                        .foregroundStyle(MoilColor.textSecondary)
                    + Text("로그인")
                        .fontWeight(.bold)
                        .foregroundStyle(MoilColor.primary)
                }
                .font(MoilTypography.regular(14))
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 402)
        }
    }
}

private struct EmailVerificationView: View {
    let onBack: () -> Void
    let onNext: () -> Void
    @State private var code = ""
    @State private var resendMessage = ""

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
                .padding(.top, 76)
                Text("moil@example로 전송된 인증번호 6자리를 입력해주세요")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 12)

                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Text(code.character(at: index))
                            .font(MoilTypography.bold(19))
                            .frame(width: 52, height: 52)
                            .background(.white)
                            .overlay { RoundedRectangle(cornerRadius: 12).stroke(index == code.count && !code.isEmpty ? MoilColor.error : .clear, lineWidth: 1) }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .overlay {
                    TextField("", text: $code)
                        .keyboardType(.numberPad)
                        .opacity(0.01)
                }
                    .onChange(of: code) { _, value in
                        code = String(value.filter(\.isNumber).prefix(6))
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
                Button("다음", action: onNext)
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(isComplete ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!isComplete)
                    .padding(.bottom, 44)
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
    let onComplete: () -> Void
    @State private var password = ""
    @State private var confirmation = ""

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
                .padding(.top, 76)
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
                Button("가입하기", action: onComplete)
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(passwordIsValid && passwordsMatch ? MoilColor.primary : MoilColor.primary.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!(passwordIsValid && passwordsMatch))
                    .padding(.bottom, 38)
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

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
            }
        }
        .textContentType(contentType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .font(MoilTypography.regular(15))
        .padding(.horizontal, 16)
        .frame(height: 53)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    AuthFlowView()
}
