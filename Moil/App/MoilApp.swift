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

    var body: some Scene {
        WindowGroup {
            AuthFlowView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
