//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendError.swift
//
//  Created by Nacho Soto on 4/7/22.

// swiftlint:disable multiline_parameters

import Foundation

/// An `Error` produced by ``Backend``.
enum BackendError: Error, Equatable {

    case networkError(NetworkError)
    case missingAppUserID(Source)
    case emptySubscriberAttributes(Source)
    case missingReceiptFile(URL?, Source)
    case missingTransactionProductIdentifier(Source)
    case missingCachedCustomerInfo(Source)
    case invalidAppleSubscriptionKey(Source)
    case unexpectedBackendResponse(UnexpectedBackendResponseError, extraContext: String?, Source)
    case invalidWebRedemptionToken
    case purchaseBelongsToOtherUser
    case expiredWebRedemptionToken(obfuscatedEmail: String)
    case unsupportedInUIPreviewMode(Source)

}

extension BackendError {

    static func missingAppUserID(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .missingAppUserID(.init(file: file, function: function, line: line))
    }

    static func emptySubscriberAttributes(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .emptySubscriberAttributes(.init(file: file, function: function, line: line))
    }

    static func missingTransactionProductIdentifier(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .missingTransactionProductIdentifier(.init(file: file, function: function, line: line))
    }

    static func missingReceiptFile(
        _ receiptURL: URL?,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .missingReceiptFile(receiptURL, .init(file: file, function: function, line: line))
    }

    static func missingCachedCustomerInfo(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .missingCachedCustomerInfo(.init(file: file, function: function, line: line))
    }

    static func unexpectedBackendResponse(
        _ error: UnexpectedBackendResponseError,
        extraContext: String? = nil,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .unexpectedBackendResponse(error,
                                          extraContext: extraContext,
                                          .init(file: file, function: function, line: line))
    }

    static func unsupportedInUIPreviewMode(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .unsupportedInUIPreviewMode(.init(file: file, function: function, line: line))
    }

}

extension BackendError: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case let .networkError(error):
            return error.asPurchasesError

        case let .missingAppUserID(source):
            return ErrorUtils.missingAppUserIDError(fileName: source.file,
                                                    functionName: source.function,
                                                    line: source.line)

        case let .emptySubscriberAttributes(source):
            return ErrorUtils.emptySubscriberAttributesError(fileName: source.file,
                                                             functionName: source.function,
                                                             line: source.line)

        case let .missingReceiptFile(receiptURL, source):
            return ErrorUtils.missingReceiptFileError(receiptURL,
                                                      fileName: source.file,
                                                      functionName: source.function,
                                                      line: source.line)

        case let .missingTransactionProductIdentifier(source):
            return ErrorUtils.unknownError(
                message: Strings.purchase.skpayment_missing_product_identifier.description,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )

        case let .missingCachedCustomerInfo(source):
            return ErrorUtils.customerInfoError(withMessage: Strings.purchase.missing_cached_customer_info.description,
                                                fileName: source.file,
                                                functionName: source.function,
                                                line: source.line)

        case let .unexpectedBackendResponse(error, extraContext, source):
            return ErrorUtils.unexpectedBackendResponse(withSubError: error,
                                                        extraContext: extraContext,
                                                        fileName: source.file,
                                                        functionName: source.function,
                                                        line: source.line)
        case let .invalidAppleSubscriptionKey(source):
            return ErrorUtils.configurationError(
                message: ErrorCode.invalidAppleSubscriptionKeyError.description,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )
        case .invalidWebRedemptionToken:
            let code = BackendErrorCode.invalidWebRedemptionToken
            return ErrorUtils.backendError(withBackendCode: code,
                                           originalBackendErrorCode: code.rawValue)
        case .purchaseBelongsToOtherUser:
            let code = BackendErrorCode.purchaseBelongsToOtherUser
            return ErrorUtils.backendError(withBackendCode: code,
                                           originalBackendErrorCode: code.rawValue)
        case let .expiredWebRedemptionToken(obfuscatedEmail):
            let code = BackendErrorCode.expiredWebRedemptionToken
            return ErrorUtils.backendError(withBackendCode: code,
                                           originalBackendErrorCode: code.rawValue,
                                           extraUserInfo: [
                                            .obfuscatedEmail: obfuscatedEmail
                                           ])
        case let .unsupportedInUIPreviewMode(source):
            return ErrorUtils.unsupportedInUIPreviewModeError(fileName: source.file,
                                                              functionName: source.function,
                                                              line: source.line)

        }
    }

}

extension BackendError: DescribableError { }

extension BackendError {

    /// Whether the operation producing this error actually synced the data.
    var successfullySynced: Bool {
        return self.networkError?.successfullySynced ?? false
    }

    /// Whether the operation producing this error can be completed.
    /// If `false`, the underlying error was fatal.
    var finishable: Bool {
        return self.networkError?.finishable ?? false
    }

    /// Whether the error represents a `NetworkError` from the server being down.
    var isServerDown: Bool {
        return self.networkError?.isServerDown == true
    }

    private var networkError: NetworkError? {
        switch self {
        case let .networkError(networkError):
            return networkError

        case .missingAppUserID,
             .emptySubscriberAttributes,
             .missingReceiptFile,
             .invalidAppleSubscriptionKey,
             .missingTransactionProductIdentifier,
             .missingCachedCustomerInfo,
             .unexpectedBackendResponse,
             .invalidWebRedemptionToken,
             .purchaseBelongsToOtherUser,
             .expiredWebRedemptionToken,
             .unsupportedInUIPreviewMode:
            return nil
        }
    }

}

extension BackendError {

    var underlyingError: Error? {
        switch self {
        case let .networkError(error):
            return error

        case .missingAppUserID,
                .emptySubscriberAttributes,
                .missingReceiptFile,
                .invalidAppleSubscriptionKey,
                .missingTransactionProductIdentifier,
                .missingCachedCustomerInfo,
                .invalidWebRedemptionToken,
                .purchaseBelongsToOtherUser,
                .expiredWebRedemptionToken,
                .unsupportedInUIPreviewMode:
            return nil

        case let .unexpectedBackendResponse(error, _, _):
            return error
        }
    }

}

extension BackendError {

    enum UnexpectedBackendResponseError: Error, Equatable {

        /// Login call failed due to a problem with the response.
        case loginResponseDecoding

        /// Received a bad response after posting an offer- "offers" couldn't be read from response.
        case postOfferIdBadResponse

        /// Received a bad response after posting an offer- "offers" was totally missing.
        case postOfferIdMissingOffersInResponse

        /// Received a bad response after posting an offer- there was an issue with the signature.
        case postOfferIdSignature

        /// getOffer call failed with an invalid response.
        case getOfferUnexpectedResponse

        /// A call that is supposed to retrieve a CustomerInfo failed because the CustomerInfo in the response was nil.
        case customerInfoNil

        /// A call that is supposed to retrieve a CustomerInfo failed because the json object couldn't be parsed.
        case customerInfoResponseParsing(error: NSError, json: String)
    }

}

extension BackendError.UnexpectedBackendResponseError: DescribableError {

    var description: String {
        switch self {
        case .loginResponseDecoding:
            return "Unable to decode response returned from login."
        case .postOfferIdBadResponse:
            return "Unable to decode response returned from posting offer for signing."
        case .postOfferIdMissingOffersInResponse:
            return "Missing offers from response returned from posting offer for signing."
        case .postOfferIdSignature:
            return "Signature error encountered in response returned from posting offer for signing."
        case .getOfferUnexpectedResponse:
            return "Unknown error encountered while getting offerings."
        case .customerInfoNil:
            return "Unable to instantiate a CustomerInfoResponse, CustomerInfo in response was nil."
        case .customerInfoResponseParsing:
            return "Unable to instantiate a CustomerInfoResponse due to malformed json."
        }
    }

}

extension BackendError {

    typealias Source = ErrorSource

}
