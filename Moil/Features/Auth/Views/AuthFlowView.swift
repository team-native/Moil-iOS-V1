import SwiftUI

struct AuthFlowView: View {
    @State private var route: AuthRoute = .login

    var body: some View {
        switch route {
        case .login:
            LoginView(showingSignUp: Binding(
                get: { route == .signUpInfo },
                set: { route = $0 ? .signUpInfo : .login }
            ))
        case .signUpInfo:
            SignUpInfoView(onBack: { route = .login }, onNext: { route = .emailVerification })
        case .emailVerification:
            EmailVerificationView(onBack: { route = .signUpInfo })
        }
    }
}

private enum AuthRoute {
    case login
    case signUpInfo
    case emailVerification
}

private struct LoginView: View {
    @Binding var showingSignUp: Bool
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 8
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MoilColor.background
                    .ignoresSafeArea()

            ScrollView {
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
                    .padding(.top, 92)

                    Spacer(minLength: 42)

                    VStack(spacing: 12) {
                        AuthTextField(title: "이메일", text: $email, contentType: .emailAddress)
                        AuthTextField(title: "비밀번호", text: $password, isSecure: true, contentType: .password)
                        HStack {
                            Spacer()
                            Button("비밀번호를 잊으셨나요?") { }
                                .font(MoilTypography.regular(13))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                    }

                    Spacer(minLength: 70)

                    VStack(spacing: 14) {
                        Button("로그인") { }
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
                    .padding(.bottom, 34)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MoilColor.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("회원가입")
                        .font(MoilTypography.bold(28))
                        .foregroundStyle(MoilColor.textPrimary)
                        .padding(.top, 38)

                    Text("이름")
                        .font(MoilTypography.semibold(12))
                        .foregroundStyle(MoilColor.textTertiary)
                        .padding(.top, 32)
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
    @State private var code = ""
    @State private var resendMessage = ""

    private var isComplete: Bool { code.count == 6 }

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary)
                        .frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                Text("이메일 인증")
                    .font(MoilTypography.bold(28))
                    .foregroundStyle(MoilColor.textPrimary)
                    .padding(.top, 38)
                Text("moil@example로 전송된 인증번호 6자리를 입력해주세요")
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilColor.textSecondary)
                    .padding(.top, 12)

                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .font(MoilTypography.bold(24))
                    .multilineTextAlignment(.center)
                    .onChange(of: code) { _, value in
                        code = String(value.filter(\.isNumber).prefix(6))
                    }
                    .frame(height: 64)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 20)

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
                Button("다음") { }
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
