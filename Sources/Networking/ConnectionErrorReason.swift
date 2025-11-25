//
//  ConnectionErrorReason.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 24/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

enum ConnectionErrorReason: String, Codable {
    case timeout = "TIMEOUT"
    case noNetwork = "NO_NETWORK"
    case other = "OTHER"
}

extension ConnectionErrorReason {
    init(from error: NetworkError) {
        switch error {
        case let .networkError(networkError, _):
            if let urlError = networkError as? URLError, urlError.code == .timedOut {
                self = .timeout
            } else {
                self = .noNetwork
            }
        case .dnsError, .unexpectedResponse:
            self = .noNetwork
        default:
            self = .other
        }
    }
}
