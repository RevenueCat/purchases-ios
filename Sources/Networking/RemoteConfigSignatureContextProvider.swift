//
//  RemoteConfigSignatureContextProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Provides the signature inputs for remote config RC Container responses.
///
/// The response signature covers the config element's stored 24-byte checksum. A `204 No Content`
/// response represents a successful no-update result and is treated as verified without signature
/// headers.
struct RemoteConfigSignatureContextProvider: ResponseSignatureContextProvider {

    let shouldTreatNoContentResponseAsVerified = true

    func responsePayloadForSignature(from body: Data?) throws -> Data? {
        return try Self.configChecksum(from: body)
    }

    func requestBodyForSignature(for request: HTTPRequest) -> HTTPRequestBody? {
        return nil
    }

}

private extension RemoteConfigSignatureContextProvider {

    /// Extracts the signed payload from a remote config RC Container response.
    ///
    /// Remote config defines the first RC Container element as the config element. The backend signs
    /// that element's stored checksum, not the full container body. This intentionally parses only
    /// the first element so verification can fail before the full response is decoded later.
    static func configChecksum(from data: Data?) throws -> Data {
        guard let data = data else {
            throw RCContainer.Parser.FormatError.missingBody
        }

        var parser = RCContainer.ElementParser(data: data)
        try parser.moveToFirstElement()
        guard parser.hasRemainingBytes else {
            throw RCContainer.Parser.FormatError.missingConfigElement
        }

        let configElement = try parser.parseElement(index: 0)
        return configElement.withChecksumBytes { bytes in
            Data(bytes)
        }
    }

}
