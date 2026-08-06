import SwiftUI

/// Shared spacing so every tab screen starts its content at the same place.
enum MoilTabScreenMetrics {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 8
}

/// Keeps the application tab bar in one fixed safe-area position for every tab screen.
struct MoilTabScreenLayout<Content: View>: View {
    let selected: MoilTab?
    var style: MoilTabBarStyle = .standard
    var isTabBarVisible = true
    let onSelect: (MoilTab) -> Void
    @ViewBuilder let content: Content

    var body: some View {
        if isTabBarVisible {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MoilTabBar(selected: selected, style: style, onSelect: onSelect)
                        .transaction { $0.animation = nil }
                }
        } else {
            content
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
