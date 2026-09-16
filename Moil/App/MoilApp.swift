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
        // @AppStorage 기본값은 UserDefaults에 키가 아예 없을 때만 적용되므로,
        // 예전 빌드에서 라이트모드로 저장된 기기는 기본값을 true로 바꿔도 반영되지 않습니다.
        // 최초 1회에 한해 강제로 다크모드로 마이그레이션합니다.
        let darkModeMigrationKey = "moilDarkModeDefaultMigrationDone"
        if !UserDefaults.standard.bool(forKey: darkModeMigrationKey) {
            UserDefaults.standard.set(true, forKey: "moilDarkMode")
            UserDefaults.standard.set(true, forKey: darkModeMigrationKey)
        }

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
        }
    }
}
