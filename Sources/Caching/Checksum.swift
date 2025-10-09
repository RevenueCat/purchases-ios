//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checksum.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 10/3/25.
//

import CryptoKit
import Foundation

/// A checksum
public struct Checksum: Codable, Sendable, Hashable {

    /// The algorithm used to generate the checksum
    public let algorithm: Algorithm

    /// the value of the checksum
    public let value: String

    /// Creates a checksum
    /// - Parameters:
    ///   - algorithm: The algorithm used
    ///   - value: The checksum hash
    public init(algorithm: Algorithm, value: String) {
        self.algorithm = algorithm
        self.value = value
    }

    enum CodingKeys: String, CodingKey {
        case algorithm = "algo"
        case value
    }

    /// The algoritms supported for generating a checksum
    public enum Algorithm: String, Codable, Sendable {
        // swiftlint:disable:next missing_docs
        case sha256, sha384, sha512, md5

        func getHasher() -> any HashFunction {
            switch self {
            case .sha256:
                return SHA256()
            case .sha384:
                return SHA384()
            case .sha512:
                return SHA512()
            case .md5:
                return Insecure.MD5()
            }
        }
    }
}

public extension Checksum {

    ///
    /// - Parameters:
    ///   - data: The data that should be hashed
    ///   - algorithm: the hashing algorithm
    /// - Returns: a ``Checksum``
    static func generate(from data: Data, with algorithm: Checksum.Algorithm) -> Checksum {
        switch algorithm {
        case .sha256:
            return Checksum(algorithm: algorithm, value: data.sha256String)
        case .sha384:
            return Checksum(algorithm: algorithm, value: data.sha384String)
        case .sha512:
            return Checksum(algorithm: algorithm, value: data.sha512String)
        case .md5:
            return Checksum(algorithm: algorithm, value: data.md5String)
        }
    }

    /// Compare to another checksum
    /// - Parameter checksome: Another Checksum
    func compare(to checksome: Checksum) throws {
        if self != checksome {
            throw ChecksumValidationFailure()
        }
    }

    /// An error describing a checksum validation failure
    struct ChecksumValidationFailure: Error { }
}
