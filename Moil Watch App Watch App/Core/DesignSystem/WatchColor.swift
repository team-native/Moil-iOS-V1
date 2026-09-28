import SwiftUI

/// watchOS는 Assets.xcassets의 "Dark Appearance" 색상을 iOS와 달리 자동으로
/// 전환해 주지 않습니다(실기기/시뮬레이터 모두 확인됨 — `.preferredColorScheme`나
/// `.environment(\.colorScheme, .dark)`를 걸어도 항상 "Any Appearance" 값만 그려집니다).
/// 그래서 화이트/다크 전환은 색상 자체를 코드에서 직접 골라 구현합니다.
enum WatchColor {
    /// 아이폰 Moil 앱의 다크/라이트 설정을 그대로 물려받습니다. 기본값은 워치의 기존 다크 톤입니다.
    static var isDarkMode = true

    static var background: Color {
        isDarkMode ? Color(red: 0.090, green: 0.086, blue: 0.075) : Color(red: 1.000, green: 1.000, blue: 1.000)
    }

    static var surface: Color {
        isDarkMode ? Color(red: 0.141, green: 0.129, blue: 0.114) : Color(red: 0.976, green: 0.976, blue: 0.973)
    }

    static var textPrimary: Color {
        isDarkMode ? Color(red: 0.953, green: 0.945, blue: 0.937) : Color(red: 0.082, green: 0.067, blue: 0.051)
    }

    static var textSecondary: Color {
        isDarkMode ? Color(red: 0.608, green: 0.596, blue: 0.569) : Color(red: 0.365, green: 0.341, blue: 0.318)
    }

    /// 멤버 색상 칩, 참석 버튼, 오늘 날짜 강조처럼 채도 높은 배경 위에 올라가는 글자용입니다.
    /// 배경 자체가 이미 색이 있어 다크/화이트 모드를 따라가면 안 되므로 항상 흰색으로 고정합니다.
    static let onAccent = Color.white
}
