//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) @testable import RevenueCat
import XCTest

final class SystemFontRegistryTests: TestCase {

    func testIsAlreadyRegisteredErrorReturnsTrueForCoreTextAlreadyRegistered() {
        let error = NSError(domain: kCTFontManagerErrorDomain as String,
                            code: CTFontManagerError.alreadyRegistered.rawValue)

        XCTAssertTrue(SystemFontRegistry.isAlreadyRegisteredError(error))
    }

    func testIsAlreadyRegisteredErrorReturnsFalseForOtherErrors() {
        let wrongDomain = NSError(domain: "com.revenuecat.test", code: 0)
        let wrongCode = NSError(domain: kCTFontManagerErrorDomain as String, code: -1)

        XCTAssertFalse(SystemFontRegistry.isAlreadyRegisteredError(wrongDomain))
        XCTAssertFalse(SystemFontRegistry.isAlreadyRegisteredError(wrongCode))
        XCTAssertFalse(SystemFontRegistry.isAlreadyRegisteredError(nil))
    }
}
