//
//  Offering+ExitPaywall.swift
//
//  Created by GPT-5.1 Codex on 12/03/24.
//

import RevenueCat

enum ExitPaywallMetadataKeys {

    static let offeringIdentifier = "rc_exit_offering_id"

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    var exitPaywallContent: PaywallViewConfiguration.Content? {
        guard let identifier = self.metadata[ExitPaywallMetadataKeys.offeringIdentifier] as? String else {
            return nil
        }

        return .offeringIdentifier(identifier, presentedOfferingContext: nil)
    }

}
