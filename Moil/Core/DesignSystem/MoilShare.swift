import SwiftUI
import MessageUI
import UIKit

/// iOS 메시지 앱 작성 화면입니다. 초대 링크를 미리 채워서 띄웁니다.
struct MoilMessageComposer: UIViewControllerRepresentable {
    let body: String
    let onFinish: () -> Void

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            onFinish()
        }
    }
}

/// iOS 기본 공유 시트입니다. 카카오톡을 포함해 설치된 앱으로 링크를 보냅니다.
struct MoilActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onFinish() }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

enum MoilShareTarget: String, Identifiable {
    case message
    case activity

    var id: String { rawValue }
}
