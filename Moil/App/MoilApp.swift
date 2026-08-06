//
//  MoilApp.swift
//  Moil
//
//  Created by 김준표 on 7/26/26.
//

import SwiftUI

@main
struct MoilApp: App {
    @AppStorage("moilDarkMode") private var isDarkMode = false
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
        }
    }
}
