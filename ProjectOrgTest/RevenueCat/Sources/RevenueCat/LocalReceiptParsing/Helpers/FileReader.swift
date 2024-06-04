//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileReader.swift
//
//  Created by Nacho Soto on 1/10/23.

import Foundation

/// A type that can read data from disk
/// Useful for mocking.
protocol FileReader {

    func contents(of url: URL) throws -> Data

}

/// Default implementation of `FileReader` that simply uses `Data`'s implementation.
final class DefaultFileReader: FileReader {

    func contents(of url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

}
