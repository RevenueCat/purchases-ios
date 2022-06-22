//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  String+Extensions.swift
//
//  Created by Juanpe Catalán on 9/7/21.
//

import Foundation

extension String {

    enum Error: Swift.Error {

        case escapingEmptyString
        case trimmingEmptyString

    }

    func rot13() -> String {
        ROT13.string(self)
    }

    func escapedOrError() throws -> String {
        let trimmedAndEscaped = self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

        guard trimmedAndEscaped.count > 0 else {
            Logger.error("Attempting to escape an empty string")
            throw Error.escapingEmptyString
        }

        return trimmedAndEscaped
    }

    func trimmedOrError() throws -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count > 0 else {
            Logger.warn("Attempting to trim an empty string")
            throw Error.trimmingEmptyString
        }

        return trimmed
    }

    /// Returns `nil` if `self` is an empty string.
    var notEmpty: String? {
        return self.isEmpty
        ? nil
        : self
    }

    /// Returns `nil` if `self` is an empty string or it only contains whitespaces.
    var notEmptyOrWhitespaces: String? {
        return self.trimmingWhitespacesAndNewLines.isEmpty
        ? nil
        : self
    }

    var trimmingWhitespacesAndNewLines: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var asData: Data {
        return Data(self.utf8)
    }

}

private enum ROT13 {

    private static let key: [Character: Character] = {
        let size = Self.lowercase.count
        let halfSize: Int = size / 2

        var result: [Character: Character] = .init(minimumCapacity: size)

        for number in 0 ..< size {
            let index = (number + halfSize) % size

            result[Self.uppercase[number]] = Self.uppercase[index]
            result[Self.lowercase[number]] = Self.lowercase[index]
        }

        return result
    }()
    private static let lowercase: [Character] = Array("abcdefghijklmnopqrstuvwxyz")
    private static let uppercase: [Character] = Self.lowercase.map { $0.uppercased().first! }

    fileprivate static func string(_ string: String) -> String {
        let transformed = string.map { Self.key[$0] ?? $0 }
        return String(transformed)
    }

}
