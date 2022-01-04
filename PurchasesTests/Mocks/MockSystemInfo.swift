//
//  MockSystemInfo.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/20/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockSystemInfo: SystemInfo {
    var stubbedIsApplicationBackgrounded: Bool?
    var stubbedIsSandbox: Bool?

    convenience init(finishTransactions: Bool) {
        // swiftlint:disable:next force_try
        try! self.init(platformFlavor: nil,
                       platformFlavorVersion: nil,
                       finishTransactions: finishTransactions)
    }

    override func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        completion(stubbedIsApplicationBackgrounded ?? false)
    }

    var stubbedIsOperatingSystemAtLeastVersion: Bool?
    override public func isOperatingSystemAtLeastVersion(_ version: OperatingSystemVersion) -> Bool {
        return stubbedIsOperatingSystemAtLeastVersion ?? true
    }

    override var isSandbox: Bool {
        return stubbedIsSandbox ?? super.isSandbox
    }

}
