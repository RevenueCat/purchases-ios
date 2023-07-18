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

    var paywallWithLocalImage: PaywallData {
        return self.paywall!.withLocalImage
    }

}

extension PaywallData {

    var withLocalImage: Self {
        var copy = self
        copy.assetBaseURL = URL(fileURLWithPath: Bundle.module.bundlePath)
        copy.config.imageNames = ["image.png"]

        return copy
    }

}
