import SwiftUI

/// 통신을 기다리는 동안 보여 주는 공통 로딩 표시입니다.
struct MoilLoadingView: View {
    var size: CGFloat = 40
    var lineWidth: CGFloat = 5
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoilColor.textTertiary.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(MoilColor.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
        }
        .frame(width: size, height: size)
        .onAppear { isSpinning = true }
        .accessibilityLabel("불러오는 중")
    }
}

/// 화면 전체를 덮는 로딩입니다.
struct MoilLoadingOverlay: View {
    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            MoilLoadingView()
        }
    }
}

#Preview("로딩") {
    MoilLoadingOverlay()
}
