import SwiftUI

enum MoilAvatarColor {
    static let blue = Color("AvatarBlue")
    static let red = Color("AvatarRed")
    static let green = Color("AvatarGreen")
    static let orange = Color("AvatarOrange")
    static let yellow = Color("AvatarYellow")
    static let purple = Color("AvatarPurple")
    static let pink = Color("AvatarPink")
}

struct MoilAvatar: View {
    let color: Color
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(color)

            HStack(spacing: size * 0.18) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
            }
            .offset(y: -size * 0.08)

            Capsule()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.33, height: size * 0.08)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("프로필")
    }
}

#Preview("피그마 프로필") {
    MoilAvatar(color: Color("AvatarGreen"))
        .padding()
        .background(MoilColor.background)
}
