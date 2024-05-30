//
//  Real_JApp.swift
//  Real_J
//
//  Created by 최가의 on 2023/07/18.
//

import SwiftUI
import Foundation
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class UserData: ObservableObject {
    @Published var userId: Int64?

    func setUserId(_ userId: Int64?) {
        self.userId = userId
    }

    func removeUserId() {
        userId = nil
    }
}

@main
struct Real_JApp: App {    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var userData = UserData()

    var body: some Scene {
        WindowGroup {
            SwiftUIView()
                .environmentObject(userData)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 앱 실행하고 알림 허용할지 팝업창
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // UNUserNotificationCenterDelegate를 구현한 메서드를 실행시킴
        application.registerForRemoteNotifications()
        
        // 파이어베이스 Meesaging 설정
        Messaging.messaging().delegate = self
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 백그라운드에서 푸시 알림을 탭했을 때 실행
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNS token: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
        // 디바이스 토큰
           let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNS token: \(tokenString)")
    }
    
    // Foreground(앱 켜진 상태)에서도 알림 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    
    // 파이어베이스 MessagingDelegate 설정
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
        
    }
}
