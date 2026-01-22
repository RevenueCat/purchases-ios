//
//  MockSystemInfo.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/20/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
@_spi(Internal) @testable import RevenueCat

// Note: this class is implicitly `@unchecked Sendable` through its parent
// even though it's not actually thread safe.
class MockSystemInfo: SystemInfo {

    var stubbedIsApplicationBackgrounded: Bool?
    var stubbedIsSandbox: Bool?
    var stubbedIsDebugBuild: Bool?
    var stubbedStorefront: StorefrontType?
    var stubbedApiKeyValidationResult: Configuration.APIKeyValidationResult?

    convenience init(platformInfo: Purchases.PlatformInfo? = nil,
                     finishTransactions: Bool,
                     customEntitlementsComputation: Bool = false,
                     storeKitVersion: StoreKitVersion = .default,
                     apiKeyValidationResult: Configuration.APIKeyValidationResult = .validApplePlatform,
                     responseVerificationMode: Signing.ResponseVerificationMode = .disabled,
                     dangerousSettings: DangerousSettings,
                     clock: ClockType = TestClock(),
                     preferredLocalesProvider: PreferredLocalesProvider = .mock()) {
        self.init(platformInfo: platformInfo,
                  finishTransactions: finishTransactions,
                  storeKitVersion: storeKitVersion,
                  apiKeyValidationResult: apiKeyValidationResult,
                  responseVerificationMode: responseVerificationMode,
                  dangerousSettings: dangerousSettings,
                  isAppBackgrounded: false,
                  clock: clock,
                  preferredLocalesProvider: preferredLocalesProvider)
    }

    convenience init(platformInfo: Purchases.PlatformInfo? = nil,
                     finishTransactions: Bool,
                     customEntitlementsComputation: Bool = false,
                     uiPreviewMode: Bool = false,
                     storeKitVersion: StoreKitVersion = .default,
                     apiKeyValidationResult: Configuration.APIKeyValidationResult = .validApplePlatform,
                     responseVerificationMode: Signing.ResponseVerificationMode = .disabled,
                     clock: ClockType = TestClock(),
                     preferredLocalesProvider: PreferredLocalesProvider = .mock()) {
        let dangerousSettings = DangerousSettings(
            autoSyncPurchases: true,
            customEntitlementComputation: customEntitlementsComputation,
            internalSettings: DangerousSettings.Internal.default,
            uiPreviewMode: uiPreviewMode
        )

        self.init(platformInfo: platformInfo,
                  finishTransactions: finishTransactions,
                  customEntitlementsComputation: customEntitlementsComputation,
                  storeKitVersion: storeKitVersion,
                  apiKeyValidationResult: apiKeyValidationResult,
                  responseVerificationMode: responseVerificationMode,
                  dangerousSettings: dangerousSettings,
                  clock: clock,
                  preferredLocalesProvider: preferredLocalesProvider)
    }

    override var isAppBackgroundedState: Bool {
        get { stubbedIsApplicationBackgrounded ?? super.isAppBackgroundedState }
        set { super.isAppBackgroundedState = newValue }
    }

    override func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        completion(stubbedIsApplicationBackgrounded ?? false)
    }

    var stubbedIsOperatingSystemAtLeastVersion: Bool?
    var stubbedCurrentOperatingSystemVersion: OperatingSystemVersion?
    override public func isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
        if let stubbedIsOperatingSystemAtLeastVersion = self.stubbedIsOperatingSystemAtLeastVersion {
            return stubbedIsOperatingSystemAtLeastVersion
        }

        if let currentVersion = self.stubbedCurrentOperatingSystemVersion {
            return currentVersion >= version
        }

        return true
    }

    override var isSandbox: Bool {
        return self.stubbedIsSandbox ?? super.isSandbox
    }

    override var isDebugBuild: Bool {
        return self.stubbedIsDebugBuild ?? super.isDebugBuild
    }

    override var storefront: StorefrontType? {
        get async {
            return self.stubbedStorefront
        }
    }

    override var apiKeyValidationResult: Configuration.APIKeyValidationResult {
        get { return self.stubbedApiKeyValidationResult ?? super.apiKeyValidationResult }
        set { super.apiKeyValidationResult = newValue }
    }
}

extension MockSystemInfo: @unchecked Sendable {}

extension OperatingSystemVersion: Swift.Comparable {

    public static func < (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        if lhs.majorVersion == rhs.majorVersion {
            if lhs.minorVersion == rhs.minorVersion {
                return lhs.patchVersion < rhs.patchVersion
            } else {
                return lhs.minorVersion < rhs.minorVersion
            }
        } else {
            return lhs.majorVersion < rhs.majorVersion
        }
    }

    public static func == (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return (
            lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.patchVersion
        )
    }

}
