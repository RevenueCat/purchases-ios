//
// Created by RevenueCat on 3/28/22.
// Copyright (c) 2022 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
final class BackendSubscriberAttributesTestsiOS13AndBelow: BaseBackendSubscriberAttributesTestClass {

    override func setUpWithError() throws {
        if #available(iOS 14.0.0, tvOS 14.0.0, macOS 11.0.0, watchOS 7.0, *) {
            throw XCTSkip("Skipping test because it's iOS 12 to 13.x only.")
        }

        try super.setUpWithError()
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
