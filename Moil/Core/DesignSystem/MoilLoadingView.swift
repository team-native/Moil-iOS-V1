import SwiftUI

/// 통신을 기다리는 동안 보여 주는 로딩 표시입니다.
/// 피그마 `533:1518` 기준입니다. 68x68 링, 두께 10.17, 90도에서 시작하는 원뿔 그라디언트.
/// 내보낸 SVG가 conic-gradient를 foreignObject로 담고 있어 iOS에서 그대로 렌더되지 않으므로
/// 같은 색 위치를 가진 그라디언트로 다시 그립니다.
struct MoilLoadingView: View {
    var size: CGFloat = 68
    @State private var isSpinning = false

    private var lineWidth: CGFloat { size * (10.1669 / 68) }

    private var sweep: AngularGradient {
        AngularGradient(
            stops: [
                .init(color: Color(red: 0.749, green: 0.420, blue: 0.376), location: 0),
                .init(color: Color(red: 0.918, green: 0.398, blue: 0.330), location: 0.17567),
                .init(color: Color.white.opacity(0), location: 1)
            ],
            center: .center,
            startAngle: .degrees(90),
            endAngle: .degrees(450)
        )
    }

    var body: some View {
        Circle()
            .strokeBorder(sweep, lineWidth: lineWidth)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
            .accessibilityLabel("불러오는 중")
    }
}

/// 통신 중에 화면 전체를 덮는 로딩 페이지입니다.
struct MoilLoadingPage: View {
    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            MoilLoadingView()
        }
    }
}

extension View {
    /// 통신 중일 때 화면을 로딩 페이지로 덮습니다.
    func moilLoading(_ isActive: Bool) -> some View {
        overlay {
            if isActive { MoilLoadingPage() }
        }
    }
}

#Preview("로딩 페이지") {
    MoilLoadingPage()
}
