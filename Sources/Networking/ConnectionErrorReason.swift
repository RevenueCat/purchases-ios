//
//  ConnectionErrorReason.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 24/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

enum ConnectionErrorReason: String, Codable {
    case timeout = "TIMEOUT"
    case noNetwork = "NO_NETWORK"
    case other = "OTHER"
}

extension ConnectionErrorReason {
    init(from error: NetworkError) {
        switch error {
        case let .networkError(networkError, _):
            guard let urlError = networkError as? URLError else {
                self = .other
                return
            }

            switch urlError.code {
            // Timeout error
            case .timedOut:
                self = .timeout

            // Network connectivity errors
            case .notConnectedToInternet,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .internationalRoamingOff,
                 .callIsActive,
                 .dataNotAllowed:
                self = .noNetwork

            // Any other URLError.code
            default:
                self = .other
            }
        case .dnsError, .unexpectedResponse:
            self = .noNetwork
        default:
            self = .other
        }
    }
}
