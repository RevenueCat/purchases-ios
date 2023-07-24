//
//  DataExtensions.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
import RevenueCat
import RevenueCatUI

// MARK: - Extensions

extension Offering {

    var withLocalImages: Offering {
        return self.mapPaywall { $0?.withLocalImages }
    }

    var withLocalReversedImages: Offering {
        return self.mapPaywall { $0?.withLocalImages.withReversedImages }
    }

    private func mapPaywall(_ mapper: (PaywallData?) -> PaywallData?) -> Self {
        return .init(
            identifier: self.identifier,
            serverDescription: self.serverDescription,
            metadata: self.metadata,
            paywall: mapper(self.paywall),
            availablePackages: self.availablePackages
        )
    }

}

extension PaywallData {

    var withLocalImages: Self {
        return self.mapImages {
            $0
               .enumerated()
               .map { index, _ in "image_\(index + 1).jpg" }
        }
    }

    /// Useful for templates where we need images to be in opposite order.
    /// For example: the background being the first image.
    var withReversedImages: Self {
        return self.mapImages { $0.reversed() }
    }

    private func mapImages(_ mapper: ([String]) -> [String]) -> Self {
        var copy = self
        copy.assetBaseURL = URL(fileURLWithPath: Bundle.module.bundlePath)
        copy.config.imageNames = mapper(self.config.imageNames)

        return copy
    }

}
