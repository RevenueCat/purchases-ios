//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseHTTPResponseTest.swift
//
//  Created by Nacho Soto on 4/12/22.

@testable import RevenueCat
import XCTest

class BaseHTTPResponseTest: TestCase {

    func decodeFixture<T: HTTPResponseBody>(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        let url = try XCTUnwrap(
            Bundle(for: BundleToken.self).url(forResource: name,
                                              withExtension: "json",
                                              subdirectory: "Fixtures"),
            "Could not find file with name: '\(name).json'",
            file: file, line: line
        )
        let data = try XCTUnwrap(Data(contentsOf: url), file: file, line: line)

        return try T.create(with: data)
    }

}

private final class BundleToken: NSObject {}
