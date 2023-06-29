//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ETagStrings.swift
//
//  Created by Nacho Soto on 6/15/23.

import Foundation

// swiftlint:disable identifier_name

enum ETagStrings {

    case clearing_cache
    case found_no_etag(URLRequest)
    case could_not_find_cached_response_in_already_retried(response: String)
    case storing_response(URLRequest, ETagManager.Response)
    case not_storing_etag(VerifiedHTTPResponse<Data?>)
    case using_etag(URLRequest, String, Date?)
    case not_using_etag(URLRequest,
                        VerificationResult,
                        needsSignatureVerification: Bool)

}

extension ETagStrings: LogMessage {

    var description: String {
        switch self {
        case .clearing_cache:
            return "Clearing ETagManager cache"

        case let .found_no_etag(request):
            return "Found no etag for request to '\(request.urlDescription)'"

        case let .could_not_find_cached_response_in_already_retried(response):
            return "We can't find the cached response, but call has already been retried. " +
                "Returning result from backend \(response)"
        case let .storing_response(request, response):
            return "Storing etag '\(response.eTag)' for request to '\(request.urlDescription)' (\(response.statusCode))"

        case let .not_storing_etag(response):
            return "Not storing etag for: '\(response.description)'"

        case let .using_etag(request, etag, validationTime):
            return "Using etag '\(etag)' for request to '\(request.urlDescription)'. " +
            "Validation time: \(validationTime?.description ?? "<null>")"

        case let .not_using_etag(request, storedVerificationResult, needsSignatureVerification):
            return "Not using etag for '\(request.urlDescription)'. " +
            "Requested verification: \(needsSignatureVerification). Stored result: \(storedVerificationResult)"
        }
    }

    var category: String { return "etags" }

}

private extension URLRequest {

    var urlDescription: String {
        return self.url?.absoluteString ?? ""
    }

}
