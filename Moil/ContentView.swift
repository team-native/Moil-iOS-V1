import SwiftUI

struct ContentView: View {
    @State private var showingSignUp = false

    var body: some View {
        Group {
            if showingSignUp {
                Text("회원가입 화면은 준비 중입니다")
            } else {
                LoginView(showingSignUp: $showingSignUp)
            }
        }
    }
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
                MoilColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 90)

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

                    Spacer(minLength: 36)

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

                    Spacer()

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
                .frame(width: min(proxy.size.width, 402))
                .frame(maxWidth: .infinity)
            }
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
    ContentView()
}
