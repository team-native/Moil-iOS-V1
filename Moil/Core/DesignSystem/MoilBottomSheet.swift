import SwiftUI

/// 화면 아래에서 올라와 맨 아래에 딱 붙는 시트입니다.
/// iOS 기본 시트는 좌우·아래에 여백을 두고 뜨고 탭바 아래에 깔려서, 직접 그립니다.
private struct MoilBottomSheetContainer<SheetContent: View>: View {
    let height: CGFloat
    let background: Color
    /// 시트 위에 또 시트를 띄울 때는 어두운 배경이 겹쳐 더 어두워지므로 한 번만 그립니다.
    let isDimmed: Bool
    let onClose: () -> Void
    @ViewBuilder let sheetContent: SheetContent
    @State private var isShown = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(isDimmed && isShown ? 0.35 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close() }

            if isShown {
                sheetContent
                    .frame(maxWidth: .infinity)
                    .frame(height: height, alignment: .top)
                    .background(background)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 60 { close() }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.21)) { isShown = true }
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.14)) { isShown = false }
        // 내려가는 모션이 끝난 뒤에 화면을 닫습니다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14, execute: onClose)
    }
}

extension View {
    /// 탭바까지 덮으면서 아래에서 올라오는 시트를 띄웁니다.
    func moilBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: CGFloat,
        background: Color,
        isDimmed: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            MoilBottomSheetContainer(
                height: height,
                background: background,
                isDimmed: isDimmed,
                onClose: { close(isPresented) },
                sheetContent: { content() }
            )
            .presentationBackground(.clear)
        }
        // 화면 자체는 모션 없이 나타나고, 시트만 아래에서 올라옵니다.
        // 그래야 어두운 배경이 시트와 함께 밀려 올라오지 않습니다.
        .transaction { $0.disablesAnimations = true }
    }

    /// 값이 있을 때만 시트를 띄우는 형태입니다.
    func moilBottomSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        height: CGFloat,
        background: Color,
        isDimmed: Bool = true,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        fullScreenCover(item: item) { value in
            MoilBottomSheetContainer(
                height: height,
                background: background,
                isDimmed: isDimmed,
                onClose: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { item.wrappedValue = nil }
                },
                sheetContent: { content(value) }
            )
            .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }
    }
}

private func close(_ isPresented: Binding<Bool>) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { isPresented.wrappedValue = false }
}
