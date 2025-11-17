//
//  AppDelegate.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import FirebaseCore
import KakaoSDKCommon
import KakaoSDKAuth
import UIKit
import Mixpanel

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        KakaoSDK.initSDK(appKey: Bundle.main.kakaoKey ?? "")
        UITextField.appearance().tintColor = .gray09
        Mixpanel.initialize(token: Bundle.main.mixpanelToken ?? "", trackAutomaticEvents: true)
        
        setupMemoryWarningNotification()
        
        return true
    }
    
    private func setupMemoryWarningNotification() {
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { _ in
                debugPrint("⚠️ 메모리 경고 발생 - 캐시 정리 시작")
                PhotoLoader.shared.cacheInfo()
                debugPrint("✅ 메모리 경고 대응 완료")
            }
        }
}
