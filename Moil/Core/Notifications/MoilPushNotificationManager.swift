import Combine
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

/// FCM(Firebase Cloud Messaging) 기반 푸시 알림을 담당합니다.
/// `GoogleService-Info.plist`가 프로젝트에 없으면 Firebase 초기화를 건너뛰고
/// 조용히 비활성 상태로 남습니다 — Firebase 콘솔 설정이 끝나기 전에도 앱이 크래시 없이 빌드/실행되도록 하기 위함입니다.
@MainActor
final class MoilPushNotificationManager: NSObject, ObservableObject {
    static let shared = MoilPushNotificationManager()

    @Published private(set) var fcmToken: String?

    private override init() {
        super.init()
    }

    func configureFirebase() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
#if DEBUG
            print("[Push] GoogleService-Info.plist가 없어 Firebase 초기화를 건너뜁니다. Firebase 콘솔에서 iOS 앱을 등록하고 파일을 받아 프로젝트에 추가해주세요.")
#endif
            return
        }
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    /// 로그인 이후 호출합니다. 이미 권한을 물어본 적이 있으면 시스템 다이얼로그 없이
    /// 현재 권한 상태만 반영하므로, 매 실행마다 불러도 안전합니다.
    func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
#if DEBUG
        print("[Push] APNs 등록 실패: \(error.localizedDescription)")
#endif
    }
}

extension MoilPushNotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            self.fcmToken = fcmToken
            guard let fcmToken else { return }
#if DEBUG
            print("[Push] FCM 토큰 발급됨: \(fcmToken)")
#endif
            // TODO: 백엔드에 디바이스 토큰 저장 API가 확정되면 여기서 서버로 전송합니다.
            // 예: try? await sessionStore.service().registerPushToken(fcmToken)
        }
    }
}

extension MoilPushNotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // TODO: 알림 탭 시 해당 그룹 화면으로 이동하는 딥링크 처리
    }
}
