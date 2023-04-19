//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SystemInfo.swift
//
//  Created by Joshua Liebowitz on 6/29/21.
//

import Foundation

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif os(watchOS)
import UIKit
import WatchKit
#elseif os(macOS)
import AppKit
#endif

class SystemInfo {

    static let appleSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    static var forceUniversalAppStore: Bool = false

    let storeKit2Setting: StoreKit2Setting
    let operationDispatcher: OperationDispatcher
    let platformFlavor: String
    let platformFlavorVersion: String?
    let responseVerificationLevel: Signing.ResponseVerificationLevel
    let dangerousSettings: DangerousSettings

    var finishTransactions: Bool {
        get { return self._finishTransactions.value }
        set { self._finishTransactions.value = newValue }
    }

    var bundle: Bundle { return self._bundle.value }

    var observerMode: Bool { return !self.finishTransactions }

    private let sandboxEnvironmentDetector: SandboxEnvironmentDetector
    private let _finishTransactions: Atomic<Bool>
    private let _bundle: Atomic<Bundle>

    var isSandbox: Bool {
        return self.sandboxEnvironmentDetector.isSandbox
    }

    static var frameworkVersion: String {
        return "4.17.11"
    }

    static var systemVersion: String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    static var platformHeader: String {
        return Self.forceUniversalAppStore ? "iOS" : self.platformHeaderConstant
    }

    var identifierForVendor: String? {
        // Should match available platforms in
        // https://developer.apple.com/documentation/uikit/uidevice?language=swift
        // https://developer.apple.com/documentation/watchkit/wkinterfacedevice?language=swift

        #if os(iOS) || os(tvOS)
            return UIDevice.current.identifierForVendor?.uuidString
        #elseif os(watchOS)
            return WKInterfaceDevice.current().identifierForVendor?.uuidString
        #elseif os(macOS) || targetEnvironment(macCatalyst)
            return isSandbox ? MacDevice.identifierForVendor?.uuidString : nil
        #else
            return nil
        #endif
    }

    static var serverHostURL: URL {
        return Self.proxyURL ?? Self.defaultServerHostURL
    }

    static var proxyURL: URL? {
        didSet {
            if let privateProxyURLString = proxyURL?.absoluteString {
                Logger.info(Strings.configure.configuring_purchases_proxy_url_set(url: privateProxyURLString))
            }
        }
    }

    private static let defaultServerHostName = "https://api.revenuecat.com"

    private static var defaultServerHostURL: URL {
        return URL(string: defaultServerHostName)!
    }

    init(platformInfo: Purchases.PlatformInfo?,
         finishTransactions: Bool,
         operationDispatcher: OperationDispatcher = .default,
         bundle: Bundle = .main,
         sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default,
         storeKit2Setting: StoreKit2Setting = .default,
         responseVerificationLevel: Signing.ResponseVerificationLevel = .default,
         dangerousSettings: DangerousSettings? = nil) throws {
        self.platformFlavor = platformInfo?.flavor ?? "native"
        self.platformFlavorVersion = platformInfo?.version
        self._bundle = .init(bundle)

        self._finishTransactions = .init(finishTransactions)
        self.operationDispatcher = operationDispatcher
        self.storeKit2Setting = storeKit2Setting
        self.sandboxEnvironmentDetector = sandboxEnvironmentDetector
        self.responseVerificationLevel = responseVerificationLevel
        self.dangerousSettings = dangerousSettings ?? DangerousSettings()
    }

    /// Asynchronous API if caller can't ensure that it's invoked in the `@MainActor`
    /// - Seealso: `isApplicationBackgrounded`
    func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        self.operationDispatcher.dispatchOnMainActor {
            completion(self.isApplicationBackgrounded)
        }
    }

    /// Synchronous API for callers in `@MainActor`.
    /// - Seealso: `isApplicationBackgrounded(completion:)`
    @MainActor
    var isApplicationBackgrounded: Bool {
    #if os(iOS) || os(tvOS)
        return self.isApplicationBackgroundedIOSAndTVOS
    #elseif os(macOS)
        return false
    #elseif os(watchOS)
        return self.isApplicationBackgroundedWatchOS
    #endif
    }

    #if targetEnvironment(simulator)
    static let isRunningInSimulator = true
    #else
    static let isRunningInSimulator = false
    #endif

    func isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
    }

    #if os(iOS) || os(tvOS)
    var sharedUIApplication: UIApplication? {
        UIApplication.value(forKey: "sharedApplication") as? UIApplication
    }
    #endif

    static func isAppleSubscription(managementURL: URL) -> Bool {
        guard let host = managementURL.host else { return false }
        return host.contains("apple.com")
    }

}

extension SystemInfo: SandboxEnvironmentDetector {}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension SystemInfo: @unchecked Sendable {}

extension SystemInfo {

    #if targetEnvironment(macCatalyst)
    static let platformHeaderConstant = "uikitformac"
    #elseif os(iOS)
    static let platformHeaderConstant = "iOS"
    #elseif os(watchOS)
    static let platformHeaderConstant = "watchOS"
    #elseif os(tvOS)
    static let platformHeaderConstant = "tvOS"
    #elseif os(macOS)
    static let platformHeaderConstant = "macOS"
    #endif

}

extension SystemInfo {

    static var applicationDidBecomeActiveNotification: Notification.Name {
        #if os(iOS) || os(tvOS)
            UIApplication.didBecomeActiveNotification
        #elseif os(macOS)
            NSApplication.didBecomeActiveNotification
        #elseif os(watchOS)
            Notification.Name.NSExtensionHostDidBecomeActive
        #endif
    }

    static var applicationWillResignActiveNotification: Notification.Name {
        #if os(iOS) || os(tvOS)
            UIApplication.willResignActiveNotification
        #elseif os(macOS)
            NSApplication.willResignActiveNotification
        #elseif os(watchOS)
            Notification.Name.NSExtensionHostWillResignActive
        #endif
    }

    var isAppExtension: Bool {
        return self.bundle.bundlePath.hasSuffix(".appex")
    }

}

private extension SystemInfo {

    #if os(iOS) || os(tvOS)

    // iOS/tvOS App extensions can't access UIApplication.sharedApplication, and will fail to compile if any calls to
    // it are made. There are no pre-processor macros available to check if the code is running in an app extension,
    // so we check if we're running in an app extension at runtime, and if not, we use KVC to call sharedApplication.
    @MainActor
    var isApplicationBackgroundedIOSAndTVOS: Bool {
        if self.isAppExtension {
            return true
        }

        guard let sharedUIApplication = self.sharedUIApplication else { return false }
        return sharedUIApplication.applicationState == .background
    }

    #elseif os(watchOS)

    @MainActor
    var isApplicationBackgroundedWatchOS: Bool {
        var isSingleTargetApplication: Bool {
            return Bundle.main.infoDictionary?.keys.contains("WKApplication") == true
        }

        // In Xcode 14 and later, you can produce watchOS apps with a single watchOS app target.
        // These single-target watchOS apps can run on watchOS 7 and later.
        #if swift(>=5.7)
        if #available(watchOS 7.0, *), self.isOperatingSystemAtLeast(.init(majorVersion: 9,
                                                                           minorVersion: 0,
                                                                           patchVersion: 0)) {
            // `WKApplication` works on both dual-target and single-target apps
            // When running on watchOS 9.0+
            return WKApplication.shared().applicationState == .background
        } else {
            if isSingleTargetApplication {
                // Before watchOS 9.0, single-target apps don't allow using `WKExtension` or `WKApplication`
                // (see https://github.com/RevenueCat/purchases-ios/issues/1891)
                // So we can't detect if it's running in the background
                return false
            } else {
                return WKExtension.shared().applicationState == .background
            }
        }
        #else
        // In Xcode 13 and earlier the system divides a watchOS app into two sections
        // (single-target apps are not supported):
        // - WatchKit app
        // - WatchKit extension

        // Before Xcode 14, single-target extensions aren't supported (and `WKApplication` isn't available)
        return WKExtension.shared().applicationState == .background
        #endif
    }

    #endif
}
