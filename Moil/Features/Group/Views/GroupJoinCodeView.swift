import SwiftUI

struct GroupJoinCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let onNext: () -> Void
    @State private var code = ""
    @State private var error: String?
    @State private var isVerified = false

    init(onNext: @escaping () -> Void = {}) { self.onNext = onNext }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary).frame(width: 32, height: 32)
                }
                Text("그룹 참여").font(MoilTypography.bold(26))
            }
            .padding(.top, 24)
            Text("초대 코드를 입력해주세요").font(MoilTypography.regular(13)).foregroundStyle(MoilColor.textSecondary).padding(.top, 8)
            Text("초대 코드").font(MoilTypography.semibold(12)).foregroundStyle(MoilColor.textTertiary).padding(.top, 30).padding(.bottom, 10)
            TextField("FAM-0000", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(MoilTypography.bold(15)).tracking(1)
                .padding(.horizontal, 17).frame(height: 56)
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(error == nil ? Color.clear : MoilColor.error, lineWidth: 1) }
                .onChange(of: code) { _, value in
                    let normalized = String(value.uppercased().prefix(8))
                    if normalized != value { code = normalized }
                    error = nil
                    isVerified = false
                }
            if let error { Text(error).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.error).padding(.top, 6) }
            if isVerified {
                HStack(spacing: 10) { Circle().fill(.blue).frame(width: 30, height: 30); Text("우리 가족에 참여할 준비가 됐어요") .font(MoilTypography.semibold(14)) }
                    .padding(.top, 16)
            }
            Spacer()
            Button(isVerified ? "다음" : "확인") {
                if isVerified { onNext() }
                else if code.uppercased() == "FAM-7X2Q" { isVerified = true }
                else { error = "존재하지 않는 초대 코드예요" }
            }
            .font(MoilTypography.bold(16)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(code.isEmpty ? MoilColor.primary.opacity(0.45) : MoilColor.primary).clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(code.isEmpty)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24).background(MoilColor.background.ignoresSafeArea())
    }
}

#Preview("그룹 참여 코드") {
    GroupJoinCodeView()
}
