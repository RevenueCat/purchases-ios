import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

// swiftlint:disable identifier_name
class AttributionDataMigratorTests: TestCase {

    static let defaultIdfa = "00000000-0000-0000-0000-000000000000"
    static let defaultIdfv = "A9CFE78C-51F8-4808-94FD-56B4535753C6"
    static let defaultIp = "192.168.1.130"
    static let defaultNetworkId = "20f0c0000aca0b00000fb0000c0f0f00"
    static let defaultRCNetworkId = "10f0c0000aca0b00000fb0000c0f0f00"

    var attributionDataMigrator: AttributionDataMigrator!

    override func setUp() {
        super.setUp()
        attributionDataMigrator = AttributionDataMigrator()
    }

    func testAdjustAttributionIsConverted() {
        let adjustData = adjustData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.adjustID.key: AttributionKey.Adjust.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.Adjust.network.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.Adjust.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.Adjust.adGroup.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.Adjust.creative.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: adjustData, expectedMapping: expectedMapping)
    }

    func testAdjustAttributionConversionDiscardsNSNullValues() {
        let adjustData = adjustData(
            withIdfa: .nsNull,
            adjustId: .nsNull,
            networkID: .nsNull,
            idfv: .nsNull,
            ip: .nsNull,
            campaign: .nsNull,
            adGroup: .nsNull,
            creative: .nsNull,
            network: .nsNull
        )
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) == 0
    }

    func testAdjustAttributionConversionGivesPreferenceToAdIdOverRCNetworkID() {
        let adjustData = adjustData(adjustId: .defaultValue, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.adjustID.key: AttributionKey.Adjust.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.Adjust.network.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.Adjust.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.Adjust.adGroup.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.Adjust.creative.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: adjustData, expectedMapping: expectedMapping)
    }

    func testAdjustAttributionConversionRemovesNSNullRCNetworkID() {
        let adjustData = adjustData(adjustId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        expect(converted[ReservedSubscriberAttribute.adjustID.key]).to(beNil())
    }

    func testAdjustAttributionConversionDiscardsRCNetworkIDCorrectly() {
        let adjustData = adjustData(adjustId: .notPresent, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        expect(converted[ReservedSubscriberAttribute.adjustID.key]).to(beNil())
    }

    func testAdjustAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let adjustData = adjustData(
            withIdfa: .notPresent,
            adjustId: .notPresent,
            networkID: .notPresent,
            idfv: .notPresent,
            ip: .notPresent,
            campaign: .notPresent,
            adGroup: .notPresent,
            creative: .notPresent,
            network: .notPresent
        )
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) == 0
    }

    func testAppsFlyerAttributionIsProperlyConverted() {
        let appsFlyerData = appsFlyerData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionDiscardsNSNullValues() {
        let appsFlyerData = appsFlyerData(
            withIDFA: .nsNull,
            appsFlyerId: .nsNull,
            networkID: .nsNull,
            idfv: .nsNull,
            channel: .nsNull,
            mediaSource: .nsNull,
            adKey: .nsNull,
            adGroup: .nsNull,
            adId: .nsNull,
            campaign: .nsNull,
            adSet: .nsNull,
            adKeywords: .nsNull,
            ip: .nsNull
        )
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) == 0
    }

    func testAppsFlyerAttributionConversionGivesPreferenceToAdIdOverRCNetworkID() {
        let appsFlyerData = appsFlyerData(appsFlyerId: .defaultValue, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConversionRemovesNSNullRCNetworkID() {
        let appsFlyerData = appsFlyerData(appsFlyerId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        expect(converted[ReservedSubscriberAttribute.appsFlyerID.key]).to(beNil())
    }

    func testAppsFlyerAttributionConversionUsesRCNetworkIDIfNoAppsFlyerID() {
        let appsFlyerData = appsFlyerData(appsFlyerId: .notPresent, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.networkID.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let appsFlyerData = appsFlyerData(
            withIDFA: .notPresent,
            appsFlyerId: .notPresent,
            networkID: .notPresent,
            idfv: .notPresent,
            channel: .notPresent,
            mediaSource: .notPresent,
            adKey: .notPresent,
            adGroup: .notPresent,
            adId: .notPresent,
            campaign: .notPresent,
            adSet: .notPresent,
            adKeywords: .notPresent,
            ip: .notPresent
        )
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) == 0
    }

    func testAppsFlyerAttributionConvertsMediaSourceAttribution() {
        let appsFlyerData = appsFlyerData(channel: .notPresent, mediaSource: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.mediaSource.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConvertsMediaSourceIfChannelIsNSNull() {
        let appsFlyerData = appsFlyerData(channel: .nsNull, mediaSource: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.mediaSource.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionGivesPreferenceToChannelOverMediaSourceWhenConvertingMediaSourceSubscriberAttribute() {
        let appsFlyerData = appsFlyerData(channel: .defaultValue, mediaSource: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesChannelAsMediaSourceSubscriberAttributeIfThereIsNoMediaSourceAttribution() {
        let appsFlyerData = appsFlyerData(channel: .defaultValue, mediaSource: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesChannelAsMediaSourceSubscriberAttributeIfMediaSourceAttributionIsNSNull() {
        let appsFlyerData = appsFlyerData(channel: .defaultValue, mediaSource: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConvertsAdGroupAttribution() {
        let appsFlyerData = appsFlyerData(adKey: .notPresent, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.adGroup.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConvertsAdGroupIfAdIsNSNull() {
        let appsFlyerData = appsFlyerData(adKey: .nsNull, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.adGroup.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    // swiftlint:disable:next line_length
    func testAppsFlyerAttributionGivesPreferenceToAdIfThereIsAdAndAdGroupAttributionWhenConvertingAdSubscriberAttribute() {
        let appsFlyerData = appsFlyerData(adKey: .defaultValue, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesAdAsAdSubscriberAttributeIfThereIsNoAdGroupAttribution() {
        let appsFlyerData = appsFlyerData(adKey: .defaultValue, adGroup: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesAdSubscriberAttributeIfAdGroupAttributionIsNSNull() {
        let appsFlyerData = appsFlyerData(adKey: .defaultValue, adGroup: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionIsProperlyConvertedIfInsideDataKeyInDictionary() {
        var appsFlyerDataWithInnerJSON: [String: Any] = ["status": 1]
        let appsFlyerData: [String: Any] = appsFlyerData()
        var appsFlyerDataClean: [String: Any] = [:]

        for (key, value) in appsFlyerData {
            if key.starts(with: "rc_") {
                appsFlyerDataWithInnerJSON[key] = value
            } else {
                appsFlyerDataClean[key] = value
            }
        }

        appsFlyerDataWithInnerJSON["data"] = appsFlyerDataClean

        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.AppsFlyer.id.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionIsProperlyConvertedIfInsideDataKeyInDictionaryAndRCNetworkID() {
        var appsFlyerDataWithInnerJSON: [String: Any] = ["status": 1]
        let appsFlyerData: [String: Any] = appsFlyerData(appsFlyerId: .notPresent, networkID: .defaultValue)
        var appsFlyerDataClean: [String: Any] = [:]

        for (key, value) in appsFlyerData {
            if key.starts(with: "rc_") {
                appsFlyerDataWithInnerJSON[key] = value
            } else {
                appsFlyerDataClean[key] = value
            }
        }

        appsFlyerDataWithInnerJSON["data"] = appsFlyerDataClean

        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.networkID.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionIsProperlyConvertedIfInsideDataKeyInDictionaryAndAndAppsFlyerIsNull() {
        var appsFlyerDataWithInnerJSON: [String: Any] = ["status": 1]
        let appsFlyerData: [String: Any] = appsFlyerData(appsFlyerId: .nsNull, networkID: .defaultValue)
        var appsFlyerDataClean: [String: Any] = [:]

        for (key, value) in appsFlyerData {
            if key.starts(with: "rc_") {
                appsFlyerDataWithInnerJSON[key] = value
            } else {
                appsFlyerDataClean[key] = value
            }
        }

        appsFlyerDataWithInnerJSON["data"] = appsFlyerDataClean

        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.appsFlyerID.key: AttributionKey.networkID.rawValue,
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.AppsFlyer.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.AppsFlyer.campaign.rawValue,
            ReservedSubscriberAttribute.adGroup.key: AttributionKey.AppsFlyer.adSet.rawValue,
            ReservedSubscriberAttribute.ad.key: AttributionKey.AppsFlyer.ad.rawValue,
            ReservedSubscriberAttribute.keyword.key: AttributionKey.AppsFlyer.adKeywords.rawValue,
            ReservedSubscriberAttribute.creative.key: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testBranchAttributionIsConverted() {
        let branchData = branchData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: branchData, network: AttributionNetwork.branch.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.mediaSource.key: AttributionKey.Branch.channel.rawValue,
            ReservedSubscriberAttribute.campaign.key: AttributionKey.Branch.campaign.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: branchData, expectedMapping: expectedMapping)
    }

    func testBranchAttributionConversionDiscardsNSNullValues() {
        let branchData = branchData(withIDFA: .nsNull, idfv: .nsNull, ip: .nsNull, channel: .nsNull,
                                    campaign: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: branchData, network: AttributionNetwork.branch.rawValue)
        expect(converted.count) == 0
    }

    func testBranchAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let branchData = branchData(withIDFA: .notPresent, idfv: .notPresent, ip: .notPresent, channel: .notPresent,
                                    campaign: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: branchData, network: AttributionNetwork.branch.rawValue)
        expect(converted.count) == 0
    }

    func testTenjinAttributionIsConverted() {
        let tenjinData = facebookOrTenjinData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: tenjinData, network: AttributionNetwork.tenjin.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
    }

    func testTenjinAttributionConversionDiscardsNSNullValues() {
        let tenjinData = facebookOrTenjinData(withIDFA: .nsNull, idfv: .nsNull, ip: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: tenjinData, network: AttributionNetwork.tenjin.rawValue)
        expect(converted.count) == 0
    }

    func testTenjinAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let tenjinData = facebookOrTenjinData(withIDFA: .notPresent, idfv: .notPresent, ip: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: tenjinData, network: AttributionNetwork.tenjin.rawValue)
        expect(converted.count) == 0
    }

    func testFacebookAttributionIsConverted() {
        let facebookData = facebookOrTenjinData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: facebookData, network: AttributionNetwork.facebook.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
    }

    func testFacebookAttributionConversionDiscardsNSNullValues() {
        let facebookData = facebookOrTenjinData(withIDFA: .nsNull, idfv: .nsNull, ip: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: facebookData, network: AttributionNetwork.facebook.rawValue)
        expect(converted.count) == 0
    }

    func testFacebookAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let facebookData = facebookOrTenjinData(withIDFA: .notPresent, idfv: .notPresent, ip: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: facebookData, network: AttributionNetwork.facebook.rawValue)
        expect(converted.count) == 0
    }

    func testMParticleAttributionIsConverted() {
        let mparticleData = mParticleData()
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.mpParticleID.key: AttributionKey.MParticle.id.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: mparticleData, expectedMapping: expectedMapping)
    }

    func testMParticleAttributionConversionDiscardsNSNullValues() {
        let mparticleData = mParticleData(withIDFA: .nsNull, idfv: .nsNull, mParticleId: .nsNull, networkID: .nsNull,
                                          ip: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) == 0
    }

    func testMParticleAttributionConversionGivesPreferenceToRCNetworkIDOverMParticleId() {
        let mparticleData = mParticleData(mParticleId: .defaultValue, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            ReservedSubscriberAttribute.mpParticleID.key: AttributionKey.networkID.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: mparticleData, expectedMapping: expectedMapping)
    }

    func testMParticleAttributionConversionRemovesNSNullRCNetworkID() {
        let mparticleData = mParticleData(mParticleId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        expect(converted[ReservedSubscriberAttribute.mpParticleID.key]).to(beNil())
    }

    func testMParticleAttributionConversionUsesMParticleIDIfNoRCNetworkID() {
        let mparticleData = mParticleData(mParticleId: .defaultValue, networkID: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        let expectedMapping = [
            ReservedSubscriberAttribute.mpParticleID.key: AttributionKey.MParticle.id.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: mparticleData, expectedMapping: expectedMapping)
    }

    func testMParticleAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let mparticleData = mParticleData(withIDFA: .notPresent, idfv: .notPresent, mParticleId: .notPresent,
                                          networkID: .notPresent, ip: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: mparticleData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) == 0
    }
}

private enum KeyPresence {
    case defaultValue, nsNull, notPresent
}

private extension AttributionDataMigratorTests {

    func checkConvertedAttributes(
        converted: [String: Any],
        original: [String: Any],
        expectedMapping: [String: String]
    ) {
        for (subscriberAttribute, attributionKey) in expectedMapping {
            expect((converted[subscriberAttribute] as? String)) == (original[attributionKey] as? String)
        }
    }

    func checkCommonAttributes(in converted: [String: Any],
                               idfa: KeyPresence = .defaultValue,
                               idfv: KeyPresence = .defaultValue,
                               ip: KeyPresence = .defaultValue) {
        let idfaValue = converted[ReservedSubscriberAttribute.idfa.key]
        switch idfa {
        case .defaultValue:
            expect(idfaValue as? String) == AttributionDataMigratorTests.defaultIdfa
        case .nsNull:
            expect(idfaValue).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(idfaValue).to(beNil())
        }

        let idfvValue = converted[ReservedSubscriberAttribute.idfv.key]
        switch idfv {
        case .defaultValue:
            expect(idfvValue as? String) == AttributionDataMigratorTests.defaultIdfv
        case .nsNull:
            expect(idfvValue).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(idfvValue).to(beNil())
        }

        let ipValue = converted[ReservedSubscriberAttribute.ip.key]
        switch ip {
        case .defaultValue:
            expect(ipValue as? String) == AttributionDataMigratorTests.defaultIp
        case .nsNull:
            expect(ipValue).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(ipValue).to(beNil())
        }
    }

    func adjustData(withIdfa idfa: KeyPresence = .defaultValue,
                    adjustId: KeyPresence = .defaultValue,
                    networkID: KeyPresence = .notPresent,
                    idfv: KeyPresence = .defaultValue,
                    ip: KeyPresence = .defaultValue,
                    campaign: KeyPresence = .defaultValue,
                    adGroup: KeyPresence = .defaultValue,
                    creative: KeyPresence = .defaultValue,
                    network: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [
            "clickLabel": "clickey",
            "trackerToken": "6abc940",
            "trackerName": "Instagram Profile::IG Spanish"
        ]

        updateMapping(inData: &data, keyPresence: idfa, key: AttributionKey.idfa.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfa)
        updateMapping(inData: &data, keyPresence: idfv, key: AttributionKey.idfv.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfv)
        updateMapping(inData: &data, keyPresence: adjustId, key: AttributionKey.Adjust.id.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        updateMapping(inData: &data, keyPresence: networkID, key: AttributionKey.networkID.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        updateMapping(inData: &data, keyPresence: ip, key: AttributionKey.ip.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIp)
        updateMapping(inData: &data, keyPresence: campaign, key: AttributionKey.Adjust.campaign.rawValue,
                      defaultValue: "IG Spanish")
        updateMapping(inData: &data, keyPresence: adGroup, key: AttributionKey.Adjust.adGroup.rawValue,
                      defaultValue: "an_ad_group")
        updateMapping(inData: &data, keyPresence: creative, key: AttributionKey.Adjust.creative.rawValue,
                      defaultValue: "a_creative")
        updateMapping(inData: &data, keyPresence: network, key: AttributionKey.Adjust.network.rawValue,
                      defaultValue: "Instagram Profile")
        return data
    }

    func appsFlyerData(withIDFA idfa: KeyPresence = .defaultValue,
                       appsFlyerId: KeyPresence = .defaultValue,
                       networkID: KeyPresence = .notPresent,
                       idfv: KeyPresence = .defaultValue,
                       channel: KeyPresence = .defaultValue,
                       mediaSource: KeyPresence = .notPresent,
                       adKey: KeyPresence = .defaultValue,
                       adGroup: KeyPresence = .notPresent,
                       adId: KeyPresence = .defaultValue,
                       campaign: KeyPresence = .defaultValue,
                       adSet: KeyPresence = .defaultValue,
                       adKeywords: KeyPresence = .defaultValue,
                       ip: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [
            "adset_id": "23847301359550211",
            "campaign_id": "23847301359200211",
            "click_time": "2021-05-04 18:08:51.000",
            "iscache": false,
            "adgroup_id": "238473013556789090",
            "is_mobile_data_terms_signed": true,
            "match_type": "srn",
            "agency": NSNull(),
            "retargeting_conversion_type": "none",
            "install_time": "2021-05-04 18:20:45.050",
            "af_status": "Non-organic",
            "http_referrer": NSNull(),
            "is_paid": true,
            "is_first_launch": false,
            "is_fb": true,
            "af_siteid": NSNull(),
            "af_message": "organic install"
        ]
        updateMapping(inData: &data, keyPresence: idfa, key: AttributionKey.idfa.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfa)
        updateMapping(inData: &data, keyPresence: idfv, key: AttributionKey.idfv.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfv)
        updateMapping(inData: &data, keyPresence: appsFlyerId, key: AttributionKey.AppsFlyer.id.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        updateMapping(inData: &data, keyPresence: networkID, key: AttributionKey.networkID.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        updateMapping(inData: &data, keyPresence: channel, key: AttributionKey.AppsFlyer.channel.rawValue,
                      defaultValue: "Facebook")
        updateMapping(inData: &data, keyPresence: mediaSource, key: AttributionKey.AppsFlyer.mediaSource.rawValue,
                      defaultValue: "Facebook Ads")
        updateMapping(inData: &data, keyPresence: adKey, key: AttributionKey.AppsFlyer.ad.rawValue,
                      defaultValue: "ad.mp4")
        updateMapping(inData: &data, keyPresence: adGroup, key: AttributionKey.AppsFlyer.adGroup.rawValue,
                      defaultValue: "1111 - tm - aaa - US - 999 v1")
        updateMapping(inData: &data, keyPresence: adId, key: AttributionKey.AppsFlyer.adId.rawValue,
                      defaultValue: "23847301457860211")
        updateMapping(inData: &data, keyPresence: campaign, key: AttributionKey.AppsFlyer.campaign.rawValue,
                      defaultValue: "0111 - mm - aaa - US - best creo 10 - Copy")
        updateMapping(inData: &data, keyPresence: adSet, key: AttributionKey.AppsFlyer.adSet.rawValue,
                      defaultValue: "0005 - tm - aaa - US - best 8")
        updateMapping(inData: &data, keyPresence: adKeywords, key: AttributionKey.AppsFlyer.adKeywords.rawValue,
                      defaultValue: "keywords for ad")
        updateMapping(inData: &data, keyPresence: ip, key: AttributionKey.ip.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIp)
        return data
    }

    func branchData(withIDFA idfa: KeyPresence = .defaultValue,
                    idfv: KeyPresence = .defaultValue,
                    ip: KeyPresence = .defaultValue,
                    channel: KeyPresence = .defaultValue,
                    campaign: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [
            "+is_first_session": false,
            "+clicked_branch_link": false
        ]
        updateMapping(inData: &data, keyPresence: idfa, key: AttributionKey.idfa.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfa)
        updateMapping(inData: &data, keyPresence: idfv, key: AttributionKey.idfv.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfv)
        updateMapping(inData: &data, keyPresence: ip, key: AttributionKey.ip.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIp)
        updateMapping(inData: &data, keyPresence: channel, key: AttributionKey.Branch.channel.rawValue,
                      defaultValue: "Facebook")
        updateMapping(inData: &data, keyPresence: campaign, key: AttributionKey.Branch.campaign.rawValue,
                      defaultValue: "Facebook Ads 01293")

        return data
    }

    func mParticleData(withIDFA idfa: KeyPresence = .defaultValue,
                       idfv: KeyPresence = .defaultValue,
                       mParticleId: KeyPresence = .defaultValue,
                       networkID: KeyPresence = .notPresent,
                       ip: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [:]

        updateMapping(inData: &data, keyPresence: idfa, key: AttributionKey.idfa.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfa)
        updateMapping(inData: &data, keyPresence: idfv, key: AttributionKey.idfv.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfv)
        updateMapping(inData: &data, keyPresence: mParticleId, key: AttributionKey.MParticle.id.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        updateMapping(inData: &data, keyPresence: networkID, key: AttributionKey.networkID.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        updateMapping(inData: &data, keyPresence: ip, key: AttributionKey.ip.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIp)
        return data
    }

    func facebookOrTenjinData(
        withIDFA idfa: KeyPresence = .defaultValue,
        idfv: KeyPresence = .defaultValue,
        ip: KeyPresence = .defaultValue
    ) -> [String: Any] {
        var data: [String: Any] = [:]
        updateMapping(inData: &data, keyPresence: idfa, key: AttributionKey.idfa.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfa)
        updateMapping(inData: &data, keyPresence: idfv, key: AttributionKey.idfv.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIdfv)
        updateMapping(inData: &data, keyPresence: ip, key: AttributionKey.ip.rawValue,
                      defaultValue: AttributionDataMigratorTests.defaultIp)
        return data
    }

    private func updateMapping(
        inData: inout [String: Any],
        keyPresence: KeyPresence,
        key: String,
        defaultValue: String
    ) {
        switch keyPresence {
        case .defaultValue:
            inData[key] = defaultValue
        case .nsNull:
            inData[key] = NSNull()
        case .notPresent:
            break
        }
    }
}
