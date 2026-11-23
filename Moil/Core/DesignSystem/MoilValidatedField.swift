import SwiftUI

/// 입력 칸의 검증 상태입니다. 상태에 따라 테두리 색과 안내 문구가 함께 바뀝니다.
enum MoilFieldState: Equatable {
    case neutral
    case success(String)
    case failure(String)
    /// 문구 없이 테두리만 빨갛게 표시합니다. 두 칸 중 한 칸에만 문구를 보여줄 때 씁니다.
    case highlighted

    var message: String? {
        switch self {
        case .neutral, .highlighted: nil
        case let .success(text), let .failure(text): text
        }
    }

    var tint: Color {
        switch self {
        case .neutral: .clear
        case .success: MoilColor.success
        case .failure, .highlighted: MoilColor.error
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        switch self {
        case .failure, .highlighted: true
        default: false
        }
    }
}

/// 라벨과 입력 칸, 검증 문구를 한 덩어리로 묶습니다.
///
/// 문구가 갑자기 생기고 사라지며 아래 내용이 툭툭 밀리던 문제를 줄이려고
/// - 문구·테두리 변화는 짧은 애니메이션으로 바꾸고,
/// - 입력 중 생기는 오류(`failureDelay`)는 타이핑이 잠깐 멈춘 뒤에 보여줍니다.
///   성공·해제는 바로 반영해, 고치는 순간 빨간 표시가 곧바로 사라지게 합니다.
struct MoilValidatedField<Field: View>: View {
    var label: String? = nil
    var state: MoilFieldState = .neutral
    /// 입력 중 오류를 늦게 띄우는 시간입니다. 서버 응답처럼 바로 보여야 하는 오류는 0으로 둡니다.
    var failureDelay: Duration = .milliseconds(600)
    @ViewBuilder let field: Field

    @State private var shownState: MoilFieldState = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                Text(label)
                    .font(MoilTypography.semibold(12))
                    .foregroundStyle(MoilColor.textTertiary)
                    .padding(.bottom, 10)
            }

            field
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(shownState.tint, lineWidth: 1)
                }

            if let message = shownState.message {
                HStack(spacing: 6) {
                    Image(systemName: shownState.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(message)
                        .font(MoilTypography.semibold(12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(shownState.tint)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .offset(y: -4)))
                .id(message)
            }
        }
        .task(id: state) {
            if state.isFailure, failureDelay > .zero, !shownState.isFailure {
                try? await Task.sleep(for: failureDelay)
                guard !Task.isCancelled else { return }
            }
            withAnimation(.easeOut(duration: 0.2)) { shownState = state }
        }
    }
}

/// 서버 응답 오류처럼 버튼 근처에 한 줄로 보여주는 안내입니다. 나타나고 사라질 때 부드럽게 바뀝니다.
struct MoilInlineError: View {
    let message: String?

    var body: some View {
        ZStack {
            if let message {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(message)
                        .font(MoilTypography.semibold(13))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(MoilColor.error)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MoilColor.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)))
                .id(message)
            }
        }
        .animation(.easeOut(duration: 0.22), value: message)
    }
}

/// 실패했을 때 입력 칸을 짧게 좌우로 흔듭니다.
struct MoilShakeEffect: GeometryEffect {
    var travel: CGFloat = 6
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 4), y: 0))
    }
}

#Preview("검증 상태 입력 칸") {
    VStack(spacing: 22) {
        MoilValidatedField(label: "이메일", state: .success("올바른 형식이에요")) {
            TextField("moil@example", text: .constant("moil@example.com")).moilField()
        }
        MoilValidatedField(label: "비밀번호", state: .failure("비밀번호는 8자 이상이어야 해요"), failureDelay: .zero) {
            TextField("비밀번호 입력", text: .constant("1234")).moilField()
        }
        MoilInlineError(message: "이메일 또는 비밀번호가 올바르지 않아요.")
    }
    .padding(24)
    .background(MoilColor.background)
}
