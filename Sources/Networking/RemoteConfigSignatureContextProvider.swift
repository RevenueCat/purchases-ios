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
/// response has no response payload, but still verifies the request context.
struct RemoteConfigSignatureContextProvider: ResponseSignatureContextProvider {

    func responsePayloadForSignature(from body: Data?, statusCode: HTTPStatusCode) throws -> Data? {
        guard statusCode != .noContent else {
            return nil
        }

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
            throw RCContainer.Parser.FormatError.missingElement(index: 0)
        }

        let configElement = try parser.parseElement(index: 0)
        try configElement.validateChecksum()

        return configElement.withChecksumBytes { bytes in
            Data(bytes)
        }
    }

}
