import SwiftUI

/// 화면 아래에 딱 붙는 시트입니다.
/// iOS 기본 시트는 좌우와 아래에 여백을 두고 떠 있어서, 피그마처럼 붙이려면 직접 그려야 합니다.
struct MoilBottomSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let height: CGFloat
    let background: Color
    /// 시트 위로 탭바가 겹쳐 그려지는 화면에서 내용이 가리지 않도록 주는 아래 여백입니다.
    var contentBottomPadding: CGFloat = 0
    let sheetContent: SheetContent

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { close() }

                        sheetContent
                            .padding(.bottom, contentBottomPadding)
                            .frame(maxWidth: .infinity)
                            .frame(height: height, alignment: .top)
                            .background(background)
                            .clipShape(
                                UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
                            )
                            // 홈 인디케이터 영역까지 시트가 이어지게 합니다.
                            .padding(.bottom, -safeAreaBottom)
                            .transition(.move(edge: .bottom))
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.height > 60 { close() }
                                    }
                            )
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { isPresented = false }
    }
}

extension View {
    func moilBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: CGFloat,
        background: Color,
        contentBottomPadding: CGFloat = 0,
        @ViewBuilder content: () -> SheetContent
    ) -> some View {
        modifier(
            MoilBottomSheet(
                isPresented: isPresented,
                height: height,
                background: background,
                contentBottomPadding: contentBottomPadding,
                sheetContent: content()
            )
        )
    }

    /// 값이 있을 때만 시트를 띄우는 형태입니다.
    func moilBottomSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        height: CGFloat,
        background: Color,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        let isPresented = Binding(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
        return modifier(
            MoilBottomSheet(
                isPresented: isPresented,
                height: height,
                background: background,
                sheetContent: Group {
                    if let value = item.wrappedValue {
                        content(value)
                    }
                } as Group<SheetContent?>
            )
        )
    }
}
