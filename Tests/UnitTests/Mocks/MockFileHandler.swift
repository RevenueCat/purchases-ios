//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockFileHandler.swift
//
//  Created by Nacho Soto on 9/5/23.

import Combine
import Foundation
@testable import RevenueCat

/// A `FileHandlerType` that stores its contents in memory
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
actor MockFileHandler: FileHandlerType {

    private var file: String = ""

    func readFile() throws -> Data {
        return self.file.asData
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func readLines() throws -> AsyncLineSequence<FileHandle.AsyncBytes> {
        let pipe = Pipe()

        pipe.fileHandleForWriting.write(self.file.asData)

        return pipe
            .fileHandleForReading
            .bytes
            .lines
    }

    func append(line: String) {
        self.file.append(line)
        self.file.append(Self.separator)
    }

    func emptyFile() throws {
        self.file.removeAll(keepingCapacity: false)
    }

    private var removeFirstLineError: Error?
    func setRemoveFirstLineError(_ error: Error) { self.removeFirstLineError = error }

    func removeFirstLines(_ count: Int) throws {
        if let removeFirstLineError {
            self.removeFirstLineError = nil
            throw removeFirstLineError
        }

        self.file = self.file
            .components(separatedBy: Self.separator)
            .dropFirst(count)
            .joined(separator: Self.separator)
    }

    private static let separator = "\n"

}
