import SwiftUI

/// 앱 화면 모드입니다. 시스템 설정을 따르거나, 라이트·다크로 고정합니다.
enum MoilThemeSetting: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "moilTheme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "시스템"
        case .light: "라이트"
        case .dark: "다크"
        }
    }

    /// 시스템을 고르면 nil을 돌려주어 기기 설정을 따르게 합니다.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
