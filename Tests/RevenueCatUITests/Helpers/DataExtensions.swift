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

    var paywallWithLocalImages: PaywallData {
        return self.paywall!.withLocalImages
    }

}

extension PaywallData {

    var withLocalImages: Self {
        var copy = self
        copy.assetBaseURL = URL(fileURLWithPath: Bundle.module.bundlePath)
        copy.config.imageNames = copy.config.imageNames
            .enumerated()
            .map { index, _ in "image_\(index + 1).jpg" }

        return copy
    }

}
