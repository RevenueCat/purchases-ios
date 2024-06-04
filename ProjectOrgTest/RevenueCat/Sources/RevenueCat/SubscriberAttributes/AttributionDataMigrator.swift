//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionDataMigrator.swift
//
//  Created by César de la Vega on 6/16/21.
//

import Foundation

class AttributionDataMigrator {

    func convertToSubscriberAttributes(attributionData: [String: Any], network: Int) -> [String: String] {
        let network = AttributionNetwork(rawValue: network)
        let attributionData = attributionData.removingNSNullValues()
        var convertedAttribution: [String: String] = [:]
        if let value = attributionData[AttributionKey.idfa.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.idfa.key] = value
        }
        if let value = attributionData[AttributionKey.idfv.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.idfv.key] = value
        }
        if let value = attributionData[AttributionKey.ip.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.ip.key] = value
        }
        if let value = attributionData[AttributionKey.gpsAdId.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.gpsAdId.key] = value
        }

        let networkSpecificSubscriberAttributes = convertNetworkSpecificSubscriberAttributes(
            for: network,
            attributionData: attributionData
        )

        return convertedAttribution.merging(networkSpecificSubscriberAttributes)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension AttributionDataMigrator: @unchecked Sendable {}

private extension AttributionDataMigrator {

    // This implementation follows the backend mapping of the attribution data to subscriber attributes
    func convertNetworkSpecificSubscriberAttributes(for network: AttributionNetwork?,
                                                    attributionData: [String: Any]) -> [String: String] {
        let networkSpecificSubscriberAttributes: [String: String]
        switch network {
        case .adjust:
            networkSpecificSubscriberAttributes = convertAdjustAttribution(attributionData)
        case .appsFlyer:
            networkSpecificSubscriberAttributes = convertAppsFlyerAttribution(attributionData)
        case .branch:
            networkSpecificSubscriberAttributes = convertBranchAttribution(attributionData)
        case .tenjin,
             .facebook:
            networkSpecificSubscriberAttributes = [:]
        case .mParticle:
            networkSpecificSubscriberAttributes = convertMParticleAttribution(attributionData)
        case .none, .appleSearchAds, .adServices:
            // Apple Search Ads & AdServices use standard attribution system
            networkSpecificSubscriberAttributes = [:]
        }

        return networkSpecificSubscriberAttributes
    }

    func convertMParticleAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.MParticle.id.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mpParticleID.key] = value
        }
        if let value = data[AttributionKey.networkID.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mpParticleID.key] = value
        }
        return convertedAttribution
    }

    func convertBranchAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.Branch.channel.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mediaSource.key] = value
        }
        if let value = data[AttributionKey.Branch.campaign.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.campaign.key] = value
        }
        return convertedAttribution
    }

    // swiftlint:disable:next cyclomatic_complexity
    func convertAppsFlyerAttribution(_ data: [String: Any]) -> [String: String] {
        var fixedData = data
        if let innerDataObject = fixedData[AttributionKey.AppsFlyer.dataKey.rawValue] as? [String: String?] {
            if fixedData[AttributionKey.AppsFlyer.statusKey.rawValue] != nil {
                for (key, value) in innerDataObject {
                    fixedData[key] = value
                }
            }
        }

        var convertedAttribution: [String: String] = [:]

        if let value = fixedData[AttributionKey.networkID.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.appsFlyerID.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.id.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.appsFlyerID.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.mediaSource.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mediaSource.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.channel.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mediaSource.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.campaign.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.campaign.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adSet.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.adGroup.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adGroup.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.ad.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.ad.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.ad.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adKeywords.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.keyword.key] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adId.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.creative.key] = value
        }

        return convertedAttribution
    }

    func convertAdjustAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.Adjust.id.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.adjustID.key] = value
        }
        if let value = data[AttributionKey.Adjust.network.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.mediaSource.key] = value
        }
        if let value = data[AttributionKey.Adjust.campaign.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.campaign.key] = value
        }
        if let value = data[AttributionKey.Adjust.adGroup.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.adGroup.key] = value
        }
        if let value = data[AttributionKey.Adjust.creative.rawValue] as? String {
            convertedAttribution[ReservedSubscriberAttribute.creative.key] = value
        }
        return convertedAttribution
    }
}
