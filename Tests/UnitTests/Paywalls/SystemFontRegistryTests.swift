//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import CoreText
@testable import RevenueCat
import XCTest

final class SystemFontRegistryTests: TestCase {

    func testAlreadyRegisteredErrorIsRecoverable() {
        let error = NSError(domain: kCTFontManagerErrorDomain as String,
                            code: CTFontManagerError.alreadyRegistered.rawValue)

        XCTAssertTrue(SystemFontRegistry.isRecoverableRegistrationError(error))
    }

    func testDuplicatedNameErrorIsRecoverable() {
        // Raised when a face with this name is already loaded from a different file,
        // e.g. one bundled through `UIAppFonts`.
        let error = NSError(domain: kCTFontManagerErrorDomain as String,
                            code: CTFontManagerError.duplicatedName.rawValue)

        XCTAssertTrue(SystemFontRegistry.isRecoverableRegistrationError(error))
    }

    func testRecoverableErrorCodesMatchCoreText() {
        // Guards against the tolerated codes silently changing meaning.
        XCTAssertEqual(CTFontManagerError.alreadyRegistered.rawValue, 105)
        XCTAssertEqual(CTFontManagerError.duplicatedName.rawValue, 305)
    }

    func testGenuineRegistrationFailuresAreNotRecoverable() {
        let failures: [CTFontManagerError] = [
            .fileNotFound,
            .insufficientPermissions,
            .unrecognizedFormat,
            .invalidFontData,
            .exceededResourceLimit,
            .notRegistered,
            .registrationFailed,
            .missingEntitlement,
            .insufficientInfo,
            .invalidFilePath,
            .unsupportedScope
        ]

        for failure in failures {
            let error = NSError(domain: kCTFontManagerErrorDomain as String, code: failure.rawValue)

            XCTAssertFalse(SystemFontRegistry.isRecoverableRegistrationError(error),
                           "Expected CTFontManagerError code \(failure.rawValue) to be surfaced")
        }
    }

    func testIsRecoverableRegistrationErrorReturnsFalseForOtherErrors() {
        // Same code, but not a CoreText error.
        let wrongDomain = NSError(domain: "com.revenuecat.test",
                                  code: CTFontManagerError.duplicatedName.rawValue)
        let wrongCode = NSError(domain: kCTFontManagerErrorDomain as String, code: -1)

        XCTAssertFalse(SystemFontRegistry.isRecoverableRegistrationError(wrongDomain))
        XCTAssertFalse(SystemFontRegistry.isRecoverableRegistrationError(wrongCode))
        XCTAssertFalse(SystemFontRegistry.isRecoverableRegistrationError(nil))
    }
}
