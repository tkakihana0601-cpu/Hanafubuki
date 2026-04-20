//
//  Hanafubuki87App.swift
//  Hanafubuki87
//
//  Created by Tomoki kakihana on 2026/03/22.
//

import SwiftUI
import SwiftData
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct Hanafubuki87App: App {
    @State private var showLaunchSplash = true
    @State private var didScheduleSplashFallback = false
    @StateObject private var analysisStore = AnalysisStore()
    @StateObject private var onlineMatchStore = OnlineMatchStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showLaunchSplash {
                    AppLaunchSplashView(isPresented: $showLaunchSplash)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
            .preferredColorScheme(.light)
            .environmentObject(analysisStore)
            .environmentObject(onlineMatchStore)
            .onAppear {
                #if canImport(GoogleMobileAds)
                MobileAds.shared.start(completionHandler: nil)
                #endif

                // スプラッシュが何らかの理由で閉じない場合のフェイルセーフ
                if !didScheduleSplashFallback {
                    didScheduleSplashFallback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        if showLaunchSplash {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showLaunchSplash = false
                            }
                        }
                    }
                }
            }
        }
        .modelContainer(for: KifuRecord.self)
    }
}
