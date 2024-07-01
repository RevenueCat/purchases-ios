//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateError.swift
//
//  Created by Nacho Soto on 7/17/23.

import Foundation
import RevenueCat

/// Error produced when processing `PaywallData`.
enum TemplateError: Error {

    /// No packages available to create a paywall.
    case noPackages

    /// No tiers available for a multi-tier paywall.
    case noTiers

    /// Paywall with missing localization.
    case noLocalization

    /// Multi-tier paywall with missing localization.
    case missingLocalization(PaywallData.Tier)

    /// Paywall configuration contained no package types.
    case emptyPackageList

    /// No packages from the `PackageType` list could be found.
    case couldNotFindAnyPackages(expectedTypes: [String])

}

extension TemplateError: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .noPackages:
            return "Attempted to display paywall with no packages."

        case .noTiers:
            return "Attempted to display a multi-tier paywall with no tiers."

        case .noLocalization:
            return "Couldn't find any localization for paywall."

        case let .missingLocalization(tier):
            return "Couldn't find localization for tier '\(tier.id)'."

        case .emptyPackageList:
            return "Paywall configuration contains no packages."

        case let .couldNotFindAnyPackages(expectedTypes):
            return "Couldn't find any requested packages: \(expectedTypes)"
        }
    }

}
