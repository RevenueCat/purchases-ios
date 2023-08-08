//
//  MockSystemInfo.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/20/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

// Note: this class is implicitly `@unchecked Sendable` through its parent
// even though it's not actually thread safe.
class MockSystemInfo: SystemInfo {

    var stubbedIsApplicationBackgrounded: Bool?
    var stubbedIsSandbox: Bool?

    convenience init(finishTransactions: Bool,
                     storeKit2Setting: StoreKit2Setting = .default,
                     customEntitlementsComputation: Bool = false,
                     clock: ClockType = TestClock()) {
        let dangerousSettings = DangerousSettings(customEntitlementComputation: customEntitlementsComputation)
        self.init(platformInfo: nil,
                  finishTransactions: finishTransactions,
                  storeKit2Setting: storeKit2Setting,
                  dangerousSettings: dangerousSettings,
                  clock: clock)
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

}

extension OperatingSystemVersion: Comparable {

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
