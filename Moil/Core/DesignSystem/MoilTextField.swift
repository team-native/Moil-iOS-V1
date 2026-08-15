import SwiftUI
import UIKit

/// 앱의 유일한 입력 칸입니다. 로그인, 회원가입, 계정 보안, 그룹 이름 등 모든 화면이 이것만 씁니다.
/// 수치는 피그마 기준입니다. 높이 53, 좌우 16, 모서리 14.
struct MoilTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var tracking: CGFloat = 0
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(MoilTypography.regular(15))
                        .foregroundStyle(MoilColor.fieldPlaceholder)
                }
                Group {
                    if isSecure && !isRevealed {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(MoilTypography.regular(15))
                .tracking(tracking)
                .foregroundStyle(MoilColor.textPrimary)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
            }

            if isSecure {
                Button {
                    // 전환에 애니메이션이 붙지 않도록 합니다.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { isRevealed.toggle() }
                } label: {
                    Image(systemName: isRevealed ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(MoilColor.fieldPlaceholder)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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

#Preview("공통 입력 칸") {
    VStack(spacing: 12) {
        MoilTextField(placeholder: "이메일", text: .constant(""))
        MoilTextField(placeholder: "비밀번호", text: .constant("12345678"), isSecure: true)
    }
    .padding(24)
    .background(MoilColor.background)
}
