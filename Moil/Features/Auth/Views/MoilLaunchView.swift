import SwiftUI

/// 시스템 런치 화면과 이어지도록 같은 배경 위에 마스코트와 워드마크를 올립니다.
struct MoilLaunchView: View {
    var body: some View {
        ZStack {
            MoilColor.launchBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image("MoilMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                Text("moil")
                    .font(MoilTypography.bold(24))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("런치 화면") {
    MoilLaunchView()
}
