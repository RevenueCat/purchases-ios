//
//  SystemInfo.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/29/21.
//  Copyright © 2021 Purchases. All rights reserved.
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

@objc(RCSystemInfo) open class SystemInfo: NSObject {

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

    public enum SystemInfoError: Error {
        case invalidInitializationData
    }

    private static let defaultServerHostName = "https://api.revenuecat.com"

    @objc public var finishTransactions: Bool
    @objc public let platformFlavor: String
    @objc public let platformFlavorVersion: String?
    @objc public static var forceUniversalAppStore: Bool = false
    @objc public static var isSandbox: Bool {
        let url = Bundle.main.appStoreReceiptURL
        guard let url = url else {
            return false
        }

        let receiptURLString = url.path
        return receiptURLString.contains("sandboxReceipt")
    }

    @objc public static var frameworkVersion: String { // TODO: automate the setting of this, if it hasn't been.
        return "3.13.0-SNAPSHOT"
    }

    @objc public static var systemVersion: String {
        return ProcessInfo().operatingSystemVersionString
    }

    @objc public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    @objc public static var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    @objc public static var platformHeader: String {
        return Self.forceUniversalAppStore ? "iOS" : platformHeaderConstant
    }

    @objc public static var identifierForVendor: String? {
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            return UIDevice.current.identifierForVendor?.uuidString
        #elseif os(watchOS)
            return WKInterfaceDevice.current().identifierForVendor?.uuidString
        #else
            return nil
        #endif
    }

    private static var defaultServerHostURL: URL {
        return URL(string: defaultServerHostName)!
    }

    @objc public static var serverHostURL: URL {
        return Self.proxyURL ?? Self.defaultServerHostURL
    }

    @objc public static var proxyURL: URL? {
        didSet {
            if let privateProxyURLString = proxyURL?.absoluteString {
                Logger.info(Strings.configure.configuring_purchases_proxy_url_set
                                .replacingOccurrences(of: "%@", with: privateProxyURLString))
            }
        }
    }

    @objc required public init(platformFlavor: String?, platformFlavorVersion: String?, finishTransactions: Bool) throws {
        self.platformFlavor = platformFlavor ?? "native"
        self.platformFlavorVersion = platformFlavorVersion

        if (platformFlavor == nil && platformFlavorVersion != nil) ||
            (platformFlavor != nil && platformFlavorVersion == nil) {
            Logger.error("RCSystemInfo initialized with non-matching platform flavor and platform flavor versions!")
            throw SystemInfoError.invalidInitializationData
        }

        self.finishTransactions = finishTransactions
    }

    @objc open func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(self.isApplicationBackgrounded)
        }
    }

    @objc open func isOperatingSystemAtLeastVersion(_ version: OperatingSystemVersion) -> Bool {
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
    }

}

@objc public extension SystemInfo {

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

    var isAppExtension: Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }

    var sharedUIApplication: UIApplication? {
        UIApplication.value(forKey: "sharedApplication") as? UIApplication
    }

    #endif
}
