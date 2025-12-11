//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWarning.swift
//
//  Created by Jacob Zivan Rakidzich on 12/11/25.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum PaywallWarning {
    case noOffering
    case noProducts(Error)
    case noPaywall(String)
    case missingLocalization
    case missingTiers
    case missingTier(String)
    case missingTierName(String)
    case invalidTemplate(String)
    case invalidVariables(Set<String>)
    case invalidIcons(Set<String>)

    var title: String {
        switch self {
        case .noPaywall:
            return "No Paywall configured"
        case .noOffering:
            return "No Offering found"
        case .noProducts:
            return "Could not fetch products"
        case .missingLocalization:
            return "Missing localization"
        case .missingTiers:
            return "No Tiers"
        case .missingTier:
            return "Tier is missing localization"
        case .missingTierName(let tier):
            return "Tier \(tier) is missing a name"
        case .invalidTemplate:
            return "Unkown Template"
        case .invalidVariables:
            return "Unrecognized variables"
        case .invalidIcons:
            return "Invalid icon names"
        }
    }

    // swiftlint:disable line_length

    var bodyText: String {
        switch self {
        case .noPaywall(let offeringID):
            return "Your `\(offeringID)` offering has no configured paywalls. Set one up in the RevenueCat Dashboard to begin."
        case .noOffering:
            return "We could not detect any offerings. Set one up in the RevenueCat Dashboard to begin."
        case .noProducts(let error):
            return "We could not fetch any products: \(error.localizedDescription)"
        case .missingLocalization:
            return "Your paywall is missing a localization. Add a localization in the RevenueCat Dashboard to begin."
        case .missingTiers:
            return "Your paywall is missing any tiers. Add some tiers in the RevenueCat Dashboard to begin."
        case .missingTier(let tierID):
            return "The tier with ID: \(tierID) is missing a localization. Add a localization in the RevenueCat Dashboard to begin."
        case .missingTierName(let tier):
            return "The tier: \(tier) is missing a name. Add a name in the RevenueCat Dashboard to continue."
        case .invalidTemplate(let string):
            return "The template with ID: `\(string)` does not exist for this version of the SDK. Please make sure to update your SDK to the latest version and try again."
        case .invalidVariables(let set):
            return "The following variables are not recognized: \(set.joined(separator: ", ")). Please check the docs for a list of valid variables."
        case .invalidIcons(let set):
            return "The following icon names are not valid: \(set.joined(separator: ", ")). Please check `PaywallIcon` for the list of valid icon names."
        }
    }

    // swiftlint:enable line_length

    var helpURL: URL? {
        switch self {
        case .noPaywall, .missingTierName, .missingTier, .missingTiers:
            return URL(string: "https://www.revenuecat.com/docs/tools/paywalls")
        case .noOffering:
            return URL(string: "https://www.revenuecat.com/docs/offerings/overview")
        case .noProducts:
            return URL(string: "https://www.revenuecat.com/docs/offerings/products-overview")
        case .invalidVariables:
            return URL(string: "https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/variables")
        default:
            return nil
        }
    }

    static func from(_ from: Offering.PaywallValidationError) -> PaywallWarning {
        switch from {
        case .missingPaywall(let offering):
            return .noPaywall(offering.id)
        case .missingLocalization:
            return .missingLocalization
        case .missingTiers:
            return .missingTiers
        case .missingTier(let tier):
            return .missingTier(tier.id)
        case .missingTierName(let tier):
            return .missingTierName(tier.id)
        case .invalidTemplate(let string):
            return .invalidTemplate(string)
        case .invalidVariables(let set):
            return .invalidVariables(set)
        case .invalidIcons(let set):
            return .invalidIcons(set)
        }
    }
}
