//
//  RatingRequestState.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public enum RatingRequestState {
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .loaded, .error:
            return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        case .loading, .loaded:
            return nil
        }
    }
}
