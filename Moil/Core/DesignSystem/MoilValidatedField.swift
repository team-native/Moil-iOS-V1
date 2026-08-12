import SwiftUI

/// 입력 칸의 검증 상태입니다. 상태에 따라 테두리 색과 안내 문구가 함께 바뀝니다.
enum MoilFieldState: Equatable {
    case neutral
    case success(String)
    case failure(String)

    var message: String? {
        switch self {
        case .neutral: nil
        case let .success(text), let .failure(text): text
        }
    }

    var tint: Color {
        switch self {
        case .neutral: .clear
        case .success: MoilColor.success
        case .failure: MoilColor.error
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// 라벨과 입력 칸, 검증 문구를 한 덩어리로 묶습니다.
struct MoilValidatedField<Field: View>: View {
    let label: String
    var state: MoilFieldState = .neutral
    @ViewBuilder let field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(MoilTypography.semibold(12))
                .foregroundStyle(MoilColor.textTertiary)
                .padding(.bottom, 10)

            field
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(state.tint, lineWidth: 1)
                }

            if let message = state.message {
                HStack(spacing: 6) {
                    if state.isSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(message)
                        .font(MoilTypography.bold(12))
                }
                .foregroundStyle(state.tint)
                .padding(.top, 8)
            }
        }
    }
}

#Preview("검증 상태 입력 칸") {
    VStack(spacing: 22) {
        MoilValidatedField(label: "이메일", state: .success("올바른 형식이에요")) {
            MoilTextField(placeholder: "moil@example", text: .constant("moil@example.com"))
        }
        MoilValidatedField(label: "비밀번호", state: .failure("비밀번호는 8자 이상이어야 해요")) {
            MoilTextField(placeholder: "비밀번호 입력", text: .constant("1234"), isSecure: true)
        }
    }
    .padding(24)
    .background(MoilColor.background)
}
