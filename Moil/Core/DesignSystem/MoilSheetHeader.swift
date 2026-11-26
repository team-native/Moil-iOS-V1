import SwiftUI

/// 팝업(시트)과 모달 화면의 공통 머리 영역입니다.
/// 제목과 취소·완료 버튼이 한 줄에 겹쳐 보이지 않도록 줄을 나눕니다.
/// - 팝업(취소·완료): 제목을 맨 위 가운데에, 버튼은 그 아래 줄 양끝에 두는 피라미드 배치입니다.
/// - 뒤로가기가 있는 화면: 뒤로 버튼 아래에 큰 제목을 왼쪽 정렬로 둡니다.
struct MoilSheetHeader: View {
    let title: String
    var subtitle: String?
    var leading: MoilSheetHeaderAction?
    var trailing: MoilSheetHeaderAction?
    /// 바깥에서 이미 좌우 여백을 준 화면(인증 화면 등)에서는 false로 둡니다.
    var addsHorizontalPadding = true

    private var isScreenStyle: Bool { leading?.isBack == true }

    var body: some View {
        Group {
            if isScreenStyle { screenHeader } else { popupHeader }
        }
        .padding(.horizontal, addsHorizontalPadding ? MoilSheetHeader.horizontalPadding : 0)
        .padding(.top, MoilSheetHeader.topPadding)
    }

    private var popupHeader: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(MoilTypography.bold(18))
                .foregroundStyle(MoilColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                    .padding(.horizontal, 12)
            }
            if leading != nil || trailing != nil {
                HStack(spacing: 0) {
                    if let leading { actionButton(leading) }
                    Spacer(minLength: 16)
                    if let trailing { actionButton(trailing) }
                }
                .frame(height: 44)
                .padding(.horizontal, -8)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 14)
    }

    private var screenHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                if let leading { actionButton(leading) }
                Spacer(minLength: 16)
                if let trailing { actionButton(trailing) }
            }
            .frame(height: 44)
            .padding(.horizontal, -8)

            Text(title)
                .font(MoilTypography.bold(24))
                .foregroundStyle(MoilColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)

            if let subtitle {
                Text(subtitle)
                    .font(MoilTypography.regular(14))
                    .foregroundStyle(MoilColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }

    /// 시트 안 입력칸·목록이 제목과 같은 왼쪽 선에서 시작하도록 함께 씁니다.
    static let horizontalPadding: CGFloat = 20
    /// 끌기 표시줄과 버튼이 붙어 보이지 않도록 둔 위 여백입니다.
    static let topPadding: CGFloat = 18

    @ViewBuilder
    private func actionButton(_ action: MoilSheetHeaderAction) -> some View {
        Button(action: action.handler) {
            Group {
                switch action.kind {
                case let .text(title, isProminent):
                    Text(title)
                        .font(isProminent ? MoilTypography.bold(16) : MoilTypography.regular(16))
                        .foregroundStyle(
                            action.isEnabled
                                ? (isProminent ? MoilColor.primary : MoilColor.textSecondary)
                                : MoilColor.textTertiary
                        )
                case let .icon(systemName, label):
                    Image(systemName: systemName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MoilColor.textPrimary)
                        .accessibilityLabel(label)
                }
            }
            .padding(.horizontal, 8)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(MoilPressableStyle())
        .disabled(!action.isEnabled)
        .animation(MoilMotion.quick, value: action.isEnabled)
    }
}

struct MoilSheetHeaderAction {
    enum Kind {
        case text(String, isProminent: Bool)
        case icon(String, label: String)
    }

    let kind: Kind
    var isEnabled = true
    let handler: () -> Void

    var isBack: Bool {
        if case let .icon(name, _) = kind { return name == "chevron.left" }
        return false
    }

    static func cancel(_ title: String = "취소", action: @escaping () -> Void) -> Self {
        Self(kind: .text(title, isProminent: false), handler: action)
    }

    static func confirm(_ title: String = "완료", isEnabled: Bool = true, action: @escaping () -> Void) -> Self {
        Self(kind: .text(title, isProminent: true), isEnabled: isEnabled, handler: action)
    }

    static func back(action: @escaping () -> Void) -> Self {
        Self(kind: .icon("chevron.left", label: "뒤로"), handler: action)
    }

    static func add(_ label: String = "일정 추가", action: @escaping () -> Void) -> Self {
        Self(kind: .icon("plus", label: label), handler: action)
    }

    static func close(action: @escaping () -> Void) -> Self {
        Self(kind: .icon("xmark", label: "닫기"), handler: action)
    }
}

#Preview("시트 머리") {
    VStack(spacing: 0) {
        MoilSheetHeader(title: "위치", leading: .cancel {}, trailing: .confirm {})
        MoilSheetHeader(title: "기본 프로필 수정", subtitle: "새 그룹에 들어갈 때 처음 값으로 쓰여요.", leading: .back {})
        Spacer()
    }
    .background(MoilColor.surface)
}
