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
        // 기본 제목을 쓰되 글꼴만 앱 전역에서 Inter로 지정합니다.
        guard let titleFont = UIFont(name: "Inter-Bold", size: 17) else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: titleFont]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    @StateObject private var groupStore = MoilGroupStore()
    @StateObject private var sessionStore = MoilSessionStore()
    @StateObject private var eventStore = MoilEventStore()

    var body: some Scene {
        WindowGroup {
            AuthFlowView()
                .environmentObject(groupStore)
                .environmentObject(sessionStore)
                .environmentObject(eventStore)
                // 날짜·시간 선택기까지 한국어로 나오도록 앱 전체 로케일을 고정합니다.
                .environment(\.locale, Locale(identifier: "ko_KR"))
        }
    }
}
