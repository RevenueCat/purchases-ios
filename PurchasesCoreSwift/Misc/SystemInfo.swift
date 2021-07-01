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

public typealias RCSystemInfo = SystemInfo

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
    @objc public static func frameworkVersion() -> String { // TODO: automate the setting of this, if it hasn't been.
        return "3.12.0-SNAPSHOT"
    }

    @objc public static func systemVersion() -> String {
        return ProcessInfo().operatingSystemVersionString
    }

    @objc public static func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    @objc public static func buildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    @objc public static func platformHeader() -> String {
        return Self.forceUniversalAppStore ? "iOS" : platformHeaderConstant
    }

    @objc public static func identifierForVendor() -> String? {
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            return UIDevice.current.identifierForVendor?.uuidString
        #elseif os(watchOS)
            return WKInterfaceDevice.current().identifierForVendor?.uuidString
        #else
            return nil
        #endif
    }

    private static var privateProxyURL: URL?
    @objc public static func proxyURL() -> URL? {
        return privateProxyURL
    }

    @objc public static func setProxyURL(_ proxyURL: URL?) {
        privateProxyURL = proxyURL
        guard let privateProxyURLString = privateProxyURL?.absoluteString else {
            return
        }
        Logger.info(Strings.configure.configuring_purchases_proxy_url_set
                        .replacingOccurrences(of: "%@", with: privateProxyURLString))
    }

    static func defaultServerHostURL() -> URL {
        return URL(string: defaultServerHostName)!
    }

    @objc public static func serverHostURL() -> URL {
        return proxyURL() ?? Self.defaultServerHostURL()
    }

    private var isApplicationBackgrounded: Bool {
    #if os(iOS) || (targetEnvironment(simulator) && os(iOS))
        return self.isApplicationBackgroundedIOS
    #elseif os(tvOS)
        return UIApplication.shared.applicationState == UIApplication.State.background
    #elseif os(macOS)
        return false
    #elseif os(watchOS)
        return  WKExtension.shared().applicationState == WKApplicationState.background
    #endif
    }

    #if os(iOS)
    // iOS App extensions can't access UIApplication.sharedApplication, and will fail to compile if any calls to
    // it are made. There are no pre-processor macros available to check if the code is running in an app extension,
    // so we check if we're running in an app extension at runtime, and if not, we use KVC to call sharedApplication.

    @objc private var isApplicationBackgroundedIOS: Bool {
        if self.isAppExtension {
            return true
        }

        return UIApplication.shared.applicationState == UIApplication.State.background
    }

    @objc private var isAppExtension: Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }

    #endif

    @available(*, deprecated, message: """
        Use (Swift) init(platformFlavor:, platformFlavorVersion:, finishTransactions:) throws
        or (objc)  -initWithPlatformFlavor: platformFlavorVersion: finishTransactions: error:
        """)
    @objc public func initWith(platformFlavor: String?, platformFlavorVersion: String?, finishTransactions: Bool) -> Self {
        do {
            let newInfo = try type(of: self).init(platformFlavor: platformFlavor,
                                                  platformFlavorVersion: platformFlavorVersion,
                                                  finishTransactions: finishTransactions)
            return newInfo
        } catch {
            let errorMessage = """
                RCSystemInfo initialized with non-matching platform flavor and platform flavor versions!
                platformFlavor: \(String(describing: platformFlavor)),
                platformFlavorVersion: \(String(describing: platformFlavorVersion)),
                finishTransactions: \(finishTransactions)
                """
            fatalError(errorMessage)
        }
    }

    @objc required public init(platformFlavor: String?, platformFlavorVersion: String?, finishTransactions: Bool) throws {
        if let platformFlavor = platformFlavor {
            self.platformFlavor = platformFlavor
        } else {
            self.platformFlavor = "native"
        }

        if let platformFlavorVersion = platformFlavorVersion {
            self.platformFlavorVersion = platformFlavorVersion
        } else {
            self.platformFlavorVersion = nil
        }

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

    open func isOperatingSystem(atLeastVersion version: OperatingSystemVersion) -> Bool {
        return isOperatingSystemAtLeastVersion(version)
    }

    @objc public func isOperatingSystemAtLeastVersion(_ version: OperatingSystemVersion) -> Bool {
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
    }
}
