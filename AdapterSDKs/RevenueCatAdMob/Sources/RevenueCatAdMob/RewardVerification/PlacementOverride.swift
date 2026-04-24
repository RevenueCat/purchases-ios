//
//  PlacementOverride.swift
//
//  Created by RevenueCat.
//

import Foundation

internal enum RewardVerificationPlacementOverride: Equatable {
    case keepLoadTimePlacement
    case override(String?)
}

internal enum RewardVerificationPlacementResolver {

    static func resolvedPlacement(
        currentPlacement: String?,
        override placementOverride: RewardVerificationPlacementOverride
    ) -> String? {
        switch placementOverride {
        case .keepLoadTimePlacement:
            return currentPlacement
        case let .override(placement):
            return placement
        }
    }
}
