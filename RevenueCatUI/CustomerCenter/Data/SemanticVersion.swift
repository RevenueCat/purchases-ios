//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SemanticVersion.swift
//
//  Created by JayShortway on 08/08/2024.

import Foundation

// swiftlint:disable force_unwrapping

struct SemanticVersion: Comparable {
    let major: UInt
    let minor: UInt
    let patch: UInt

    init(major: UInt, minor: UInt, patch: UInt) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(_ version: String) throws {
        let pattern = #"^(\d+)(?:\.(\d+))?(?:\.(\d+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: version, range: NSRange(version.startIndex..., in: version)) else {
            throw SemanticVersionError.invalidVersionString(version)
        }

        let major = UInt(version[Range(match.range(at: 1), in: version)!])!
        let minor = match.range(at: 2).location != NSNotFound ?
            UInt(version[Range(match.range(at: 2), in: version)!])! :
            0
        let patch = match.range(at: 3).location != NSNotFound ?
            UInt(version[Range(match.range(at: 3), in: version)!])! :
            0

        self.init(major: major, minor: minor, patch: patch)
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        } else {
            return lhs.patch < rhs.patch
        }
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
}

enum SemanticVersionError: LocalizedError {
    case invalidVersionString(String)

    var errorDescription: String? {
        switch self {
        case .invalidVersionString(let version):
            return "Invalid version string: '\(version)'. Expected format: 'major.minor.patch'"
        }
    }
}
