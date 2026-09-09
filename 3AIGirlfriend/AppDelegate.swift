//
//  AppDelegate.swift
//  3AIGirlfriend
//
//  Created by Roman on 8/8/26.
//

import UIKit
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppsFlyerLib.shared().appsFlyerDevKey = "Xpot5ZNgdk6XZr8CFUqRER"
        AppsFlyerLib.shared().appleAppID = "6809699998"
        AppsFlyerLib.shared().delegate = self
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ATT first (when needed), then AppsFlyer — do not call start() in didFinishLaunching.
        AppTrackingCoordinator.requestAuthorizationIfNeeded(delay: 0.6) { status in
            AppsFlyerLib.shared().start()
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        print("[AppsFlyer] onConversionDataSuccess: \(data)")
        
        if let status = data["af_status"] as? String {
            switch status {
            case "Non-organic":
                if let source = data["media_source"] as? String,
                   let campaign = data["campaign"] as? String {
                    print("[AppsFlyer] ✅ Non-organic install from: \(source) / \(campaign)")
                }
            case "Organic":
                print("[AppsFlyer] ✅ Organic install")
            default:
                print("[AppsFlyer] Status: \(status)")
            }
        }
        
        // Сохраните conversion data для последующего использования
        if let isFirstLaunch = data["is_first_launch"] as? Bool, isFirstLaunch {
            print("[AppsFlyer] 🎉 First launch detected!")
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        print("[AppsFlyer] ❌ onConversionDataFail: \(error.localizedDescription)")
    }
    
    func onAppOpenAttribution(_ data: [AnyHashable: Any]) {
        print("[AppsFlyer] onAppOpenAttribution: \(data)")
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print("[AppsFlyer] onAppOpenAttributionFailure: \(error.localizedDescription)")
    }


}

