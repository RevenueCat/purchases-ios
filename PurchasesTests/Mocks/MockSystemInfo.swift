//
//  MockSystemInfo.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/20/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

class MockSystemInfo: RCSystemInfo {
    var stubbedIsApplicationBackgrounded: Bool?

    override func isApplicationBackgrounded(completion: @escaping (Bool) -> Void) {
        completion(stubbedIsApplicationBackgrounded ?? false)
    }

    var stubbedIsOperatingSystemAtLeastVersion: Bool?
    override func isOperatingSystem(atLeastVersion version: OperatingSystemVersion) -> Bool {
        return stubbedIsOperatingSystemAtLeastVersion ?? true
    }
}
