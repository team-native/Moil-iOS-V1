import SwiftUI

/// 회원가입 때 받은 이름을 기기에 저장해 두고 화면 곳곳에서 씁니다.
/// 로그인 응답에는 이름이 없어서, 이 값이 내 이름의 기준이 됩니다.
enum MoilLocalAccount {
    static let nameKey = "moilUserName"
    static let colorKey = "moilProfileColorId"

    static var name: String {
        get { UserDefaults.standard.string(forKey: nameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var colorId: String? {
        get { UserDefaults.standard.string(forKey: colorKey) }
        set { UserDefaults.standard.set(newValue, forKey: colorKey) }
    }

    /// 저장된 이름이 없으면 서버에서 받은 닉네임을, 그것도 없으면 "나"를 씁니다.
    static func displayName(fallback: String?) -> String {
        let stored = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }
        let fallback = fallback?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fallback.isEmpty ? "나" : fallback
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: colorKey)
    }
}
