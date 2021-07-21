//
//  AttributionDataMigrator.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCAttributionDataMigrator) public class AttributionDataMigrator: NSObject {

    @objc public func convertToSubscriberAttributes(attributionData: [String: Any], network: Int) -> [String: Any] {
        let network = AttributionNetwork(rawValue: network)
        let attributionData = attributionData.removingNSNullValues()
        var convertedAttribution: [String: Any] = [:]
        if let value = attributionData[AttributionKey.idfa.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.idfa] = value
        }
        if let value = attributionData[AttributionKey.idfv.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.idfv] = value
        }
        if let value = attributionData[AttributionKey.ip.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.ip] = value
        }
        if let value = attributionData[AttributionKey.gpsAdId.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.gpsAdId] = value
        }

        let networkSpecificSubscriberAttributes = convertNetworkSpecificSubscriberAttributes(for: network,
                attributionData: attributionData)

        return convertedAttribution.merging(networkSpecificSubscriberAttributes) { (_, new) -> Any? in
            new
        }
    }

}

private extension AttributionDataMigrator {

    // This implementation follows the backend mapping of the attribution data to subscriber attributes
    func convertNetworkSpecificSubscriberAttributes(for network: AttributionNetwork?,
                                                    attributionData: [String: Any]) -> [String: Any] {
        let networkSpecificSubscriberAttributes: [String: Any]
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

    func convertMParticleAttribution(_ data: [String: Any]) -> [String: Any] {
        var convertedAttribution: [String: Any] = [:]
        if let value = data[AttributionKey.MParticle.id.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mpParticleID] = value
        }
        if let value = data[AttributionKey.networkID.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mpParticleID] = value
        }
        return convertedAttribution
    }

    func convertBranchAttribution(_ data: [String: Any]) -> [String: Any] {
        var convertedAttribution: [String: Any] = [:]
        if let value = data[AttributionKey.Branch.channel.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = data[AttributionKey.Branch.campaign.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        return convertedAttribution
    }

    // swiftlint:disable cyclomatic_complexity
    func convertAppsFlyerAttribution(_ data: [String: Any]) -> [String: Any] {
        var fixedData = data
        if let innerDataObject = fixedData[AttributionKey.AppsFlyer.dataKey.rawValue] as? [String: Any?] {
            if fixedData[AttributionKey.AppsFlyer.statusKey.rawValue] != nil {
                for (key, value) in innerDataObject {
                    fixedData[key] = value
                }
            }
        }

        var convertedAttribution: [String: Any] = [:]

        if let value = fixedData[AttributionKey.networkID.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.appsFlyerID] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.id.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.appsFlyerID] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.mediaSource.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.channel.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.campaign.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adSet.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.adGroup] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adGroup.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.ad] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.ad.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.ad] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adKeywords.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.keyword] = value
        }
        if let value = fixedData[AttributionKey.AppsFlyer.adId.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.creative] = value
        }

        return convertedAttribution
    }

    func convertAdjustAttribution(_ data: [String: Any]) -> [String: Any] {
        var convertedAttribution: [String: Any] = [:]
        if let value = data[AttributionKey.Adjust.id.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.adjustID] = value
        }
        if let value = data[AttributionKey.Adjust.network.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.mediaSource] = value
        }
        if let value = data[AttributionKey.Adjust.campaign.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.campaign] = value
        }
        if let value = data[AttributionKey.Adjust.adGroup.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.adGroup] = value
        }
        if let value = data[AttributionKey.Adjust.creative.rawValue] {
            convertedAttribution[SpecialSubscriberAttributes.creative] = value
        }
        return convertedAttribution
    }
}
