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

    func rot13() -> String {
        ROT13.string(self)
    }

    var trimmedAndEscaped: String {
        return self
            .trimmingWhitespacesAndNewLines
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
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

    /// Returns `true` if it contains anything other than whitespaces.
    var isNotEmpty: Bool {
        return self.notEmptyOrWhitespaces != nil
    }

    var trimmingWhitespacesAndNewLines: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var asData: Data {
        return Data(self.utf8)
    }

    func countOccurences(of character: Character) -> Int {
        return self.reduce(0) {
            return $1 == character ? $0 + 1 : $0
        }
    }

}

// MARK: -

internal extension Optional where Wrapped == String {

    /// Returns `nil` if `self` is an empty string.
    var notEmpty: String? {
        return self.flatMap { $0.notEmpty }
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
    // swiftlint:disable:next force_unwrapping
    private static let uppercase: [Character] = Self.lowercase.map { $0.uppercased().first! }

    fileprivate static func string(_ string: String) -> String {
        let transformed = string.map { Self.key[$0] ?? $0 }
        return String(transformed)
    }

}
