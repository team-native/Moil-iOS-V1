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
                Color.moilBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 90)

                    VStack(spacing: 6) {
                        Image("MoilMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 74)
                        Text("모일")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.moilText)
                        Text("각자의 시간이 모여, 우리의 약속이 되는 곳")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.moilSubtext)
                    }

                    Spacer(minLength: 36)

                    VStack(spacing: 12) {
                        AuthTextField(title: "이메일", text: $email, contentType: .emailAddress)
                        AuthTextField(title: "비밀번호", text: $password, isSecure: true, contentType: .password)
                        HStack {
                            Spacer()
                            Button("비밀번호를 잊으셨나요?") { }
                                .font(.system(size: 13))
                                .foregroundStyle(Color.moilSubtext)
                        }
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        Button("로그인") { }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(canSubmit ? Color.moilPrimary : Color.moilPrimary.opacity(0.78))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .disabled(!canSubmit)

                        Button {
                            showingSignUp = true
                        } label: {
                            Text("계정이 없으신가요? ")
                                .foregroundStyle(Color.moilSubtext)
                            + Text("회원가입")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.moilPrimary)
                        }
                        .font(.system(size: 14))
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
        .font(.system(size: 15))
        .padding(.horizontal, 16)
        .frame(height: 53)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension Color {
    static let moilBackground = Color(red: 246 / 255, green: 245 / 255, blue: 242 / 255)
    static let moilPrimary = Color(red: 191 / 255, green: 107 / 255, blue: 96 / 255)
    static let moilText = Color(red: 21 / 255, green: 17 / 255, blue: 13 / 255)
    static let moilSubtext = Color(red: 93 / 255, green: 87 / 255, blue: 81 / 255)
}

#Preview {
    ContentView()
}
