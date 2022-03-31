//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
final class BackendSubscriberAttributesTestsiOS14AndAbove: BaseBackendSubscriberAttributesTestClass {

    override func setUpWithError() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            print("Skipping test because it's iOS 14+ only.")
            throw XCTSkip("Skipping test because it's iOS 14+ only.")
        }

        try super.setUpWithError()
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
