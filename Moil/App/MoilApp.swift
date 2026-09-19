//
//  MoilApp.swift
//  Moil
//
//  Created by 김준표 on 7/26/26.
//

import SwiftUI
import UIKit

@main
struct MoilApp: App {
    init() {
        // 툴바 항목으로 제목을 그리면 화면 전환이 끝난 뒤에야 나타나므로
        // 기본 제목을 쓰되 글꼴만 앱 전역에서 Pretendard로 지정합니다.
        guard let titleFont = UIFont(name: "Pretendard-Bold", size: 17) else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: titleFont]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    @UIApplicationDelegateAdaptor(MoilAppDelegate.self) private var appDelegate
    @AppStorage("moilDarkMode") private var isDarkMode = true
    @StateObject private var groupStore = MoilGroupStore()
    @StateObject private var sessionStore = MoilSessionStore()
    @StateObject private var eventStore = MoilEventStore()

    var body: some Scene {
        WindowGroup {
            AuthFlowView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environmentObject(groupStore)
                .environmentObject(sessionStore)
                .environmentObject(eventStore)
                .onChange(of: sessionStore.isAuthenticated) { _, isAuthenticated in
                    guard isAuthenticated else { return }
                    MoilPushNotificationManager.shared.requestAuthorization()
                }
                .onChange(of: sessionStore.accessToken) { _, _ in syncWatch() }
                .onChange(of: groupStore.selectedGroupId) { _, _ in syncWatch() }
                .onAppear {
                    MoilWatchConnectivityManager.shared.activate()
                    syncWatch()
                }
        }
    }

    /// 워치는 자체 로그인 화면이 없으므로, 아이폰의 로그인 세션과 선택된 그룹을
    /// 바뀔 때마다 워치로 넘겨 그대로 이어서 서버에 접속할 수 있게 합니다.
    private func syncWatch() {
        MoilWatchConnectivityManager.shared.sync(
            accessToken: sessionStore.accessToken,
            refreshToken: sessionStore.refreshToken,
            groupId: groupStore.selectedGroupId
        )
    }
}
