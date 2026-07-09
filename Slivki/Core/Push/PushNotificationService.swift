import Foundation
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class PushNotificationService: ObservableObject {
    public static let shared = PushNotificationService()

    @Published public private(set) var deviceToken: String?
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var pendingRoute: AppRoute?

    private init() {}

    public func refreshAuthorizationStatus() async {
        #if canImport(UIKit)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        #endif
    }

    public func requestPermissionAndRegister() async {
        #if canImport(UIKit)
        let center = UNUserNotificationCenter.current()
        center.delegate = AppNotificationDelegate.shared
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            guard granted else {
                return
            }
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            await refreshAuthorizationStatus()
        }
        #endif
    }

    public func updateDeviceToken(_ tokenData: Data) {
        deviceToken = tokenData.map { String(format: "%02x", $0) }.joined()
    }

    public func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        if let route = route(from: userInfo) {
            pendingRoute = route
        }
    }

    public func consumePendingRoute() -> AppRoute? {
        defer { pendingRoute = nil }
        return pendingRoute
    }

    public func syncTokenIfNeeded(using apiClient: APIClient, isAuthenticated: Bool) async {
        guard isAuthenticated, let token = deviceToken, !token.isEmpty else {
            return
        }

        #if DEBUG
        let environment: PushEnvironment = .sandbox
        #else
        let environment: PushEnvironment = .production
        #endif

        let request = PushTokenRequest(
            token: token,
            environment: environment,
            deviceID: Self.deviceID
        )

        do {
            try await apiClient.postNoResponse(.pushToken, body: request)
        } catch {
            // Best-effort registration; retry on next auth/bootstrap refresh.
        }
    }

    private func route(from userInfo: [AnyHashable: Any]) -> AppRoute? {
        let orderID = userInfo["orderId"] as? String
            ?? userInfo["order_id"] as? String
            ?? (userInfo["orderId"] as? NSNumber)?.stringValue
            ?? (userInfo["order_id"] as? NSNumber)?.stringValue

        if let orderID, !orderID.isEmpty {
            return .order(id: orderID)
        }

        if let type = userInfo["type"] as? String, type == "orders" {
            return .orders
        }

        return nil
    }

    private static var deviceID: String? {
        #if canImport(UIKit)
        return UIDevice.current.identifierForVendor?.uuidString
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        PushNotificationService.shared.handleNotificationPayload(response.notification.request.content.userInfo)
    }
}

public final class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = AppNotificationDelegate.shared
        return true
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationService.shared.updateDeviceToken(deviceToken)
        }
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Simulator often fails APNs registration; ignore.
    }

    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleNotificationPayload(userInfo)
            completionHandler(.newData)
        }
    }
}
#endif
