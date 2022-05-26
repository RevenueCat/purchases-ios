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

    let storeKit2Setting: StoreKit2Setting
    var finishTransactions: Bool
    let operationDispatcher: OperationDispatcher
    let platformFlavor: String
    let platformFlavorVersion: String?
    let bundle: Bundle
    let dangerousSettings: DangerousSettings

    static var forceUniversalAppStore: Bool = false
    var isSandbox: Bool {
        let url = self.bundle.appStoreReceiptURL
        guard let url = url else {
            return false
        }

        let receiptURLString = url.path
        return receiptURLString.contains("sandboxReceipt")
    }

    static var frameworkVersion: String {
        return "4.4.0"
    }

    static var systemVersion: String {
        return ProcessInfo().operatingSystemVersionString
    }

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    static var platformHeader: String {
        return Self.forceUniversalAppStore ? "iOS" : platformHeaderConstant
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
         storeKit2Setting: StoreKit2Setting = .default,
         dangerousSettings: DangerousSettings? = nil) throws {
        self.platformFlavor = platformInfo?.flavor ?? "native"
        self.platformFlavorVersion = platformInfo?.version
        self.bundle = bundle

        self.finishTransactions = finishTransactions
        self.operationDispatcher = operationDispatcher
        self.storeKit2Setting = storeKit2Setting
        self.dangerousSettings = dangerousSettings ?? DangerousSettings()
    }

    func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        self.operationDispatcher.dispatchOnMainThread {
            completion(self.isApplicationBackgrounded)
        }
    }

    func isOperatingSystemAtLeastVersion(_ version: OperatingSystemVersion) -> Bool {
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

    var isApplicationBackgrounded: Bool {
    #if os(iOS) || os(tvOS)
        return self.isApplicationBackgroundedIOSAndTVOS
    #elseif os(macOS)
        return false
    #elseif os(watchOS)
        return WKExtension.shared().applicationState == WKApplicationState.background
    #endif
    }

    #if os(iOS) || os(tvOS)
    // iOS/tvOS App extensions can't access UIApplication.sharedApplication, and will fail to compile if any calls to
    // it are made. There are no pre-processor macros available to check if the code is running in an app extension,
    // so we check if we're running in an app extension at runtime, and if not, we use KVC to call sharedApplication.
    var isApplicationBackgroundedIOSAndTVOS: Bool {
        if self.isAppExtension {
            return true
        }

        guard let sharedUIApplication = self.sharedUIApplication else { return false }
        return sharedUIApplication.applicationState == UIApplication.State.background
    }

    #endif
}
