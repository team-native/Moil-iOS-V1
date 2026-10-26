import UIKit

/// 키보드가 떠 있을 때 입력 칸이 아닌 곳을 누르면 키보드를 내립니다.
/// 화면마다 배경에 탭 제스처를 붙이면 스크롤뷰·시트처럼 배경이 가려진 곳에서는 동작하지 않아,
/// 키보드가 올라올 때 창(window) 전체에 한 번만 제스처를 붙입니다.
/// 탭을 가로채지 않으므로 버튼은 키보드를 내리면서 그대로 눌립니다.
@MainActor
final class MoilKeyboardDismissal: NSObject, UIGestureRecognizerDelegate {
    static let shared = MoilKeyboardDismissal()

    private var installedWindows = NSHashTable<UIWindow>.weakObjects()

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows where !installedWindows.contains(window) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            installedWindows.add(window)
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        recognizer.view?.endEditing(true)
    }

    /// 다른 입력 칸을 눌러 옮겨 갈 때 키보드가 내려갔다 올라오지 않도록 입력 칸 터치는 무시합니다.
    nonisolated func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        MainActor.assumeIsolated {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }
    }

    nonisolated func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
