import SwiftUI

/// 아이폰 앱(MoilGroupStore)과 동일한 서버 색상 팔레트입니다. 같은 colorId가
/// 두 기기에서 다른 색으로 보이지 않도록 RGB 값을 그대로 맞췄습니다.
enum MemberColorPalette {
    private static let paletteById: [String: Color] = [
        "RED": Color(red: 244 / 255, green: 67 / 255, blue: 54 / 255),
        "ORANGE": Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255),
        "YELLOW": Color(red: 255 / 255, green: 235 / 255, blue: 59 / 255),
        "GREEN": Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255),
        "BLUE": Color(red: 33 / 255, green: 150 / 255, blue: 243 / 255),
        "NAVY": Color(red: 25 / 255, green: 55 / 255, blue: 109 / 255),
        "INDIGO": Color(red: 63 / 255, green: 81 / 255, blue: 181 / 255),
        "PURPLE": Color(red: 156 / 255, green: 39 / 255, blue: 176 / 255),
        "PINK": Color(red: 233 / 255, green: 30 / 255, blue: 99 / 255),
        "CREAM": Color(red: 255 / 255, green: 248 / 255, blue: 225 / 255),
        "PEACH": Color(red: 255 / 255, green: 204 / 255, blue: 188 / 255),
        "APRICOT": Color(red: 255 / 255, green: 183 / 255, blue: 77 / 255),
        "TAN": Color(red: 188 / 255, green: 143 / 255, blue: 107 / 255),
        "GOLD": Color(red: 255 / 255, green: 193 / 255, blue: 7 / 255),
        "CORAL": Color(red: 255 / 255, green: 111 / 255, blue: 97 / 255),
        "ROSE": Color(red: 233 / 255, green: 90 / 255, blue: 119 / 255),
        "SKY": Color(red: 3 / 255, green: 169 / 255, blue: 244 / 255),
        "LIGHT_BLUE": Color(red: 129 / 255, green: 212 / 255, blue: 250 / 255),
        "MINT": Color(red: 128 / 255, green: 203 / 255, blue: 196 / 255),
        "TEAL": Color(red: 0 / 255, green: 150 / 255, blue: 136 / 255),
        "LIGHT_GREEN": Color(red: 139 / 255, green: 195 / 255, blue: 74 / 255),
        "VIVID_GREEN": Color(red: 0 / 255, green: 200 / 255, blue: 83 / 255),
        "VIOLET": Color(red: 103 / 255, green: 58 / 255, blue: 183 / 255),
        "MAGENTA": Color(red: 216 / 255, green: 27 / 255, blue: 96 / 255),
        "VIVID_ORANGE": Color(red: 255 / 255, green: 87 / 255, blue: 34 / 255),
        "VIVID_RED": Color(red: 213 / 255, green: 0 / 255, blue: 0 / 255),
        "WARM_PINK": Color(red: 255 / 255, green: 64 / 255, blue: 129 / 255),
    ]

    static func color(for colorId: String?) -> Color {
        guard let colorId, let color = paletteById[colorId.uppercased()] else { return paletteById["GREEN"]! }
        return color
    }
}
