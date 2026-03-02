//
//  trueworld2_0App.swift
//  trueworld2.0
//
//  Created by Kendall Gipson on 2/24/26.
//

import SwiftUI
import StripePaymentSheet

@main
struct trueworld2_0App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isBooted = false
    
    var body: some Scene {
        WindowGroup {
            if isBooted {
                ContentView()
                    .transition(.opacity)
            } else {
                EngineBootView(isBooted: $isBooted)
                    .transition(.opacity)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        StripeAPI.defaultPublishableKey = "pk_test_51SvWsn5sQeZw7kiw0ImQgQnRysijfMeds9RFyaH2en6YtFEWlM4gr1XmV8Oo7brsrvSWBDVBMnIv1Cl6fPbpVwUt00bz7x2VF0"
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        Task { @MainActor in
            await NotificationManager.shared.setAPNSToken(token)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}
