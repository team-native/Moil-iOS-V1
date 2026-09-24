import SwiftUI

/// watchOS에서 `ScrollView(.horizontal)`는 축과 상관없이 디지털 크라운에 바로 반응합니다.
/// 세로 스크롤 화면 안에 이런 가로 줄이 있으면, 화면에 들어가자마자 크라운만 돌려도
/// 이 줄이 먼저 옆으로 밀려버립니다(`.focusable(false)`로도 못 끊어냄 — 크라운 연결이
/// SwiftUI 포커스 시스템이 아니라 ScrollView 자체에 있기 때문). 크라운과는 완전히 무관하고
/// 손가락 드래그로만 움직여야 하는 줄(멤버 동그라미, 참석자 줄 등)에 대신 사용합니다.
struct CrownSafeHorizontalScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var committedOffset: CGFloat = 0
    @GestureState private var liveTranslation: CGFloat = 0
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        GeometryReader { outer in
            content()
                .fixedSize()
                .background(
                    GeometryReader { inner in
                        Color.clear
                            .onAppear { contentWidth = inner.size.width }
                            .onChange(of: inner.size.width) { _, newValue in contentWidth = newValue }
                    }
                )
                .offset(x: clampedOffset(committedOffset + liveTranslation, containerWidth: outer.size.width))
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .updating($liveTranslation) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            committedOffset = clampedOffset(committedOffset + value.translation.width, containerWidth: outer.size.width)
                        }
                )
        }
    }

    private func clampedOffset(_ value: CGFloat, containerWidth: CGFloat) -> CGFloat {
        guard contentWidth > containerWidth else { return 0 }
        let minOffset = containerWidth - contentWidth
        return min(0, max(value, minOffset))
    }
}
