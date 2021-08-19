//
//  AttributionDataMigrator.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCAttributionDataMigrator) public class AttributionDataMigrator: NSObject {

    func convertToSubscriberAttributes(attributionData: [String: Any], network: Int) -> [String: String] {
        let network = AttributionNetwork(rawValue: network)
        let attributionData = attributionData.removingNSNullValues()
        var convertedAttribution: [String: String] = [:]
        if let value = attributionData[AttributionKey.idfa.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.idfa] = value
        }
        if let value = attributionData[AttributionKey.idfv.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.idfv] = value
        }
        if let value = attributionData[AttributionKey.ip.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.ip] = value
        }
        if let value = attributionData[AttributionKey.gpsAdId.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.gpsAdId] = value
        }

        let networkSpecificSubscriberAttributes = convertNetworkSpecificSubscriberAttributes(for: network,
                attributionData: attributionData)

        return convertedAttribution.merging(networkSpecificSubscriberAttributes)
    }

}

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
        case .none, .appleSearchAds:
            // Apple Search Ads uses standard attribution system
            networkSpecificSubscriberAttributes = [:]
        }

        return networkSpecificSubscriberAttributes
    }

    func convertMParticleAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.MParticle.id.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mpParticleID] = value
        }
        if let value = data[AttributionKey.networkID.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mpParticleID] = value
        }
        return convertedAttribution
    }

    func convertBranchAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.Branch.channel.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = data[AttributionKey.Branch.campaign.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        return convertedAttribution
    }

    // swiftlint:disable cyclomatic_complexity
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
            convertedAttribution[SpecialSubscriberAttributes.appsFlyerID] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.id.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.appsFlyerID] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.mediaSource.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.channel.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.campaign.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adSet.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.adGroup] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adGroup.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.ad] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.ad.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.ad] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adKeywords.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.keyword] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adId.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.creative] = value
        }

        return convertedAttribution
    }

    func convertAdjustAttribution(_ data: [String: Any]) -> [String: String] {
        var convertedAttribution: [String: String] = [:]
        if let value = data[AttributionKey.Adjust.id.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.adjustID] = value
        }
        if let value = data[AttributionKey.Adjust.network.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = data[AttributionKey.Adjust.campaign.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        if let value = data[AttributionKey.Adjust.adGroup.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.adGroup] = value
        }
        if let value = data[AttributionKey.Adjust.creative.rawValue] as? String {
            convertedAttribution[SpecialSubscriberAttributes.creative] = value
        }
        return convertedAttribution
    }
}
