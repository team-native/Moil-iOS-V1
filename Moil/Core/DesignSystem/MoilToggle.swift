import SwiftUI

/// 앱의 모든 켜기/끄기 스위치가 쓰는 공통 토글입니다.
/// iOS 기본 토글 대신 브랜드 색과 크기를 직접 그리고, 모션 없이 바로 바뀝니다.
struct MoilToggle: View {
    let title: String
    @Binding var isOn: Bool

    private let width: CGFloat = 51
    private let height: CGFloat = 31

    var body: some View {
        HStack(spacing: 12) {
                if !title.isEmpty {
                    Text(title)
                        .font(MoilTypography.regular(15))
                        .foregroundStyle(MoilColor.textPrimary)
                }
                Spacer(minLength: 0)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? MoilColor.primary : MoilColor.toggleOff)
                        .frame(width: width, height: height)
                    Circle()
                        .fill(.white)
                        .frame(width: height - 4, height: height - 4)
                        .padding(2)
                }
                .frame(width: width, height: height)
        }
        .contentShape(Rectangle())
        // 버튼으로 만들면 누르는 동안 글자까지 흐려져 깜박여 보여서 탭 제스처를 씁니다.
        .onTapGesture {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { isOn.toggle() }
        }
    }
}

#Preview("토글") {
    VStack(spacing: 20) {
        MoilToggle(title: "다크 모드", isOn: .constant(true))
        MoilToggle(title: "알림 받기", isOn: .constant(false))
    }
    .padding(24)
    .background(MoilColor.background)
}
