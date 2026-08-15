import SwiftUI

/// Shared spacing so every tab screen starts its content at the same place.
enum MoilTabScreenMetrics {
    /// 피그마 기준 좌우 여백입니다. 모든 화면이 이 값을 씁니다.
    static let horizontalPadding: CGFloat = 24
    static let topPadding: CGFloat = 8
    /// 입력 칸 묶음 사이 간격입니다. 모든 폼이 이 값을 씁니다.
    static let fieldSpacing: CGFloat = 14
    /// 상태 표시줄과 제목이 붙어 보이지 않도록 제목 위에 넉넉히 띄웁니다.
    static let titleTopPadding: CGFloat = 28
    static let titleBottomPadding: CGFloat = 20
}

/// Keeps the application tab bar in one fixed safe-area position for every tab screen.
struct MoilTabScreenLayout<Content: View>: View {
    let selected: MoilTab?
    var style: MoilTabBarStyle = .standard
    var isTabBarVisible = true
    let onSelect: (MoilTab) -> Void
    @ViewBuilder let content: Content

    var body: some View {
        // 보이고 숨길 때 구조가 바뀌면 화면 전체가 다시 그려지면서
        // 위에 얹은 화면의 전환 모션이 사라집니다. 그래서 한 구조로 유지합니다.
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isTabBarVisible {
                    MoilTabBar(selected: selected, style: style, onSelect: onSelect)
                        .transaction { $0.animation = nil }
                }
            }
    }
}

extension View {
    func moilTabScreenLayout(
        selected: MoilTab?,
        style: MoilTabBarStyle = .standard,
        isTabBarVisible: Bool = true,
        onSelect: @escaping (MoilTab) -> Void
    ) -> some View {
        MoilTabScreenLayout(
            selected: selected,
            style: style,
            isTabBarVisible: isTabBarVisible,
            onSelect: onSelect
        ) {
            self
        }
    }
}
