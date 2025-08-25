//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  JsonLoader.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/25.

import Foundation
import XCTest

enum JsonLoader {

    static func data(
        for fileName: String,
        in subDirectory: String = "JSON",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Data {
        let url = try XCTUnwrap(
            URL(fileURLWithPath: String(describing: file))
                        .deletingLastPathComponent()
                        .appendingPathComponent(subDirectory)
                        .appendingPathComponent(fileName + ".json"),
            "Could not find file with name: '\(fileName).json'",
            file: file,
            line: line
        )
        return try XCTUnwrap(Data(contentsOf: url), file: file, line: line)
    }
}
