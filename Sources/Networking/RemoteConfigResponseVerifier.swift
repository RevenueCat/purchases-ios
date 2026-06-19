//
//  RemoteConfigResponseVerifier.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Extracts the signed payload for remote config RC Container responses.
///
/// Remote config defines the first RC Container element as the config element. The backend signature
/// is computed over that element's stored 24-byte checksum, not over the full container body.
enum RemoteConfigResponseVerifier {

    static func signatureMessage(from data: Data?) throws -> Data {
        guard let data = data else {
            throw RCContainer.Parser.FormatError.truncatedHeader
        }

        var parser = RCContainer.ElementParser(data: data)
        _ = try parser.parseHeader()
        guard parser.hasRemainingBytes else {
            throw RCContainer.Parser.FormatError.missingConfigElement
        }

        let configElement = try parser.parseElement(index: 0)
        return configElement.withChecksumBytes { bytes in
            Data(bytes)
        }
    }

}
