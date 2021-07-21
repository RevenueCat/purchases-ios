import XCTest
import Nimble
import StoreKit

@testable import PurchasesCoreSwift

class AttributionDataMigratorTests: XCTestCase {

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
            SpecialSubscriberAttributes.adjustID: AttributionKey.Adjust.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.Adjust.network.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.Adjust.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.Adjust.adGroup.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.Adjust.creative.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: adjustData, expectedMapping: expectedMapping)
    }

    func testAdjustAttributionConversionDiscardsNSNullValues() {
        let adjustData = adjustData(withIdfa: .nsNull, adjustId: .nsNull, networkID: .nsNull, idfv: .nsNull,
                ip: .nsNull, campaign: .nsNull, adGroup: .nsNull, creative: .nsNull, network: .nsNull)
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
            SpecialSubscriberAttributes.adjustID: AttributionKey.Adjust.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.Adjust.network.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.Adjust.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.Adjust.adGroup.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.Adjust.creative.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: adjustData, expectedMapping: expectedMapping)
    }

    func testAdjustAttributionConversionRemovesNSNullRCNetworkID() {
        let adjustData = adjustData(adjustId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        expect(converted[SpecialSubscriberAttributes.adjustID]).to(beNil())
    }

    func testAdjustAttributionConversionDiscardsRCNetworkIDCorrectly() {
        let adjustData = adjustData(adjustId: .notPresent, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: adjustData, network: AttributionNetwork.adjust.rawValue)
        expect(converted.count) != 0
        expect(converted[SpecialSubscriberAttributes.adjustID]).to(beNil())
    }

    func testAdjustAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let adjustData = adjustData(withIdfa: .notPresent, adjustId: .notPresent, networkID: .notPresent,
                idfv: .notPresent, ip: .notPresent, campaign: .notPresent, adGroup: .notPresent, creative: .notPresent,
                network: .notPresent)
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionDiscardsNSNullValues() {
        let appsFlyerData = appsFlyerData(withIDFA: .nsNull, appsFlyerId: .nsNull, networkID: .nsNull, idfv: .nsNull,
                channel: .nsNull, mediaSource: .nsNull, ad: .nsNull, adGroup: .nsNull, adId: .nsNull, campaign: .nsNull,
                adSet: .nsNull, adKeywords: .nsNull, ip: .nsNull)
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConversionRemovesNSNullRCNetworkID() {
        let appsFlyerData = appsFlyerData(appsFlyerId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        expect(converted[SpecialSubscriberAttributes.appsFlyerID]).to(beNil())
    }

    func testAppsFlyerAttributionConversionUsesRCNetworkIDIfNoAppsFlyerID() {
        let appsFlyerData = appsFlyerData(appsFlyerId: .notPresent, networkID: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.networkID.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConversionWorksIfStandardKeysAreNotPassed() {
        let appsFlyerData = appsFlyerData(withIDFA: .notPresent, appsFlyerId: .notPresent, networkID: .notPresent,
                idfv: .notPresent, channel: .notPresent, mediaSource: .notPresent, ad: .notPresent,
                adGroup: .notPresent, adId: .notPresent, campaign: .notPresent, adSet: .notPresent,
                adKeywords: .notPresent, ip: .notPresent)
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.mediaSource.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.mediaSource.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConvertsAdGroupAttribution() {
        let appsFlyerData = appsFlyerData(ad: .notPresent, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.adGroup.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionConvertsAdGroupIfAdIsNSNull() {
        let appsFlyerData = appsFlyerData(ad: .nsNull, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.adGroup.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerAttributionGivesPreferenceToAdIfThereIsAdAndAdGroupAttributionWhenConvertingAdSubscriberAttribute() {
        let appsFlyerData = appsFlyerData(ad: .defaultValue, adGroup: .defaultValue)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesAdAsAdSubscriberAttributeIfThereIsNoAdGroupAttribution() {
        let appsFlyerData = appsFlyerData(ad: .defaultValue, adGroup: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: appsFlyerData, expectedMapping: expectedMapping)
    }

    func testAppsFlyerConversionUsesAdSubscriberAttributeIfAdGroupAttributionIsNSNull() {
        let appsFlyerData = appsFlyerData(ad: .defaultValue, adGroup: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: appsFlyerData, network: AttributionNetwork.appsFlyer.rawValue)
        expect(converted.count) != 0
        checkCommonAttributes(in: converted)
        let expectedMapping = [
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.AppsFlyer.id.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.networkID.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
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
            SpecialSubscriberAttributes.appsFlyerID: AttributionKey.networkID.rawValue,
            SpecialSubscriberAttributes.mediaSource: AttributionKey.AppsFlyer.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.AppsFlyer.campaign.rawValue,
            SpecialSubscriberAttributes.adGroup: AttributionKey.AppsFlyer.adSet.rawValue,
            SpecialSubscriberAttributes.ad: AttributionKey.AppsFlyer.ad.rawValue,
            SpecialSubscriberAttributes.keyword: AttributionKey.AppsFlyer.adKeywords.rawValue,
            SpecialSubscriberAttributes.creative: AttributionKey.AppsFlyer.adId.rawValue
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
            SpecialSubscriberAttributes.mediaSource: AttributionKey.Branch.channel.rawValue,
            SpecialSubscriberAttributes.campaign: AttributionKey.Branch.campaign.rawValue
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
            SpecialSubscriberAttributes.mpParticleID: AttributionKey.MParticle.id.rawValue
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
            SpecialSubscriberAttributes.mpParticleID: AttributionKey.networkID.rawValue
        ]
        checkConvertedAttributes(converted: converted, original: mparticleData, expectedMapping: expectedMapping)
    }

    func testMParticleAttributionConversionRemovesNSNullRCNetworkID() {
        let mparticleData = mParticleData(mParticleId: .notPresent, networkID: .nsNull)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        expect(converted[SpecialSubscriberAttributes.mpParticleID]).to(beNil())
    }

    func testMParticleAttributionConversionUsesMParticleIDIfNoRCNetworkID() {
        let mparticleData = mParticleData(mParticleId: .defaultValue, networkID: .notPresent)
        let converted = attributionDataMigrator.convertToSubscriberAttributes(
                attributionData: mparticleData, network: AttributionNetwork.mParticle.rawValue)
        expect(converted.count) != 0
        let expectedMapping = [
            SpecialSubscriberAttributes.mpParticleID: AttributionKey.MParticle.id.rawValue
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
            expect((converted[subscriberAttribute] as! String)) == (original[attributionKey] as! String)
        }
    }

    func checkCommonAttributes(in converted: [String: Any],
                               idfa: KeyPresence = .defaultValue,
                               idfv: KeyPresence = .defaultValue,
                               ip: KeyPresence = .defaultValue) {
        switch idfa {
        case .defaultValue:
            expect((converted[SpecialSubscriberAttributes.idfa] as! String)) == AttributionDataMigratorTests.defaultIdfa
        case .nsNull:
            expect(converted[SpecialSubscriberAttributes.idfa]).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(converted[SpecialSubscriberAttributes.idfa]).to(beNil())
        }
        switch idfv {
        case .defaultValue:
            expect((converted[SpecialSubscriberAttributes.idfv] as! String)) == AttributionDataMigratorTests.defaultIdfv
        case .nsNull:
            expect(converted[SpecialSubscriberAttributes.idfv]).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(converted[SpecialSubscriberAttributes.idfv]).to(beNil())
        }
        switch ip {
        case .defaultValue:
            expect((converted[SpecialSubscriberAttributes.ip] as! String)) == AttributionDataMigratorTests.defaultIp
        case .nsNull:
            expect(converted[SpecialSubscriberAttributes.ip]).to(beAKindOf(NSNull.self))
        case .notPresent:
            expect(converted[SpecialSubscriberAttributes.ip]).to(beNil())
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

        function(keyPresence: idfa, data: &data, key: AttributionKey.idfa.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfa)
        function(keyPresence: idfv, data: &data, key: AttributionKey.idfv.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfv)
        function(keyPresence: adjustId, data: &data, key: AttributionKey.Adjust.id.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        function(keyPresence: networkID, data: &data, key: AttributionKey.networkID.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        function(keyPresence: ip, data: &data, key: AttributionKey.ip.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIp)
        function(keyPresence: campaign, data: &data, key: AttributionKey.Adjust.campaign.rawValue,
                defaultValue: "IG Spanish")
        function(keyPresence: adGroup, data: &data, key: AttributionKey.Adjust.adGroup.rawValue,
                defaultValue: "an_ad_group")
        function(keyPresence: creative, data: &data, key: AttributionKey.Adjust.creative.rawValue,
                defaultValue: "a_creative")
        function(keyPresence: network, data: &data, key: AttributionKey.Adjust.network.rawValue,
                defaultValue: "Instagram Profile")
        return data
    }

    func appsFlyerData(withIDFA idfa: KeyPresence = .defaultValue,
                       appsFlyerId: KeyPresence = .defaultValue,
                       networkID: KeyPresence = .notPresent,
                       idfv: KeyPresence = .defaultValue,
                       channel: KeyPresence = .defaultValue,
                       mediaSource: KeyPresence = .notPresent,
                       ad: KeyPresence = .defaultValue,
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
        function(keyPresence: idfa, data: &data, key: AttributionKey.idfa.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfa)
        function(keyPresence: idfv, data: &data, key: AttributionKey.idfv.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfv)
        function(keyPresence: appsFlyerId, data: &data, key: AttributionKey.AppsFlyer.id.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        function(keyPresence: networkID, data: &data, key: AttributionKey.networkID.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        function(keyPresence: channel, data: &data, key: AttributionKey.AppsFlyer.channel.rawValue,
                defaultValue: "Facebook")
        function(keyPresence: mediaSource, data: &data, key: AttributionKey.AppsFlyer.mediaSource.rawValue,
                defaultValue: "Facebook Ads")
        function(keyPresence: ad, data: &data, key: AttributionKey.AppsFlyer.ad.rawValue,
                defaultValue: "ad.mp4")
        function(keyPresence: adGroup, data: &data, key: AttributionKey.AppsFlyer.adGroup.rawValue,
                defaultValue: "1111 - tm - aaa - US - 999 v1")
        function(keyPresence: adId, data: &data, key: AttributionKey.AppsFlyer.adId.rawValue,
                defaultValue: "23847301457860211")
        function(keyPresence: campaign, data: &data, key: AttributionKey.AppsFlyer.campaign.rawValue,
                defaultValue: "0111 - mm - aaa - US - best creo 10 - Copy")
        function(keyPresence: adSet, data: &data, key: AttributionKey.AppsFlyer.adSet.rawValue,
                defaultValue: "0005 - tm - aaa - US - best 8")
        function(keyPresence: adKeywords, data: &data, key: AttributionKey.AppsFlyer.adKeywords.rawValue,
                defaultValue: "keywords for ad")
        function(keyPresence: ip, data: &data, key: AttributionKey.ip.rawValue,
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
        function(keyPresence: idfa, data: &data, key: AttributionKey.idfa.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfa)
        function(keyPresence: idfv, data: &data, key: AttributionKey.idfv.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfv)
        function(keyPresence: ip, data: &data, key: AttributionKey.ip.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIp)
        function(keyPresence: channel, data: &data, key: AttributionKey.Branch.channel.rawValue,
                defaultValue: "Facebook")
        function(keyPresence: campaign, data: &data, key: AttributionKey.Branch.campaign.rawValue,
                defaultValue: "Facebook Ads 01293")

        return data
    }

    func mParticleData(withIDFA idfa: KeyPresence = .defaultValue,
                       idfv: KeyPresence = .defaultValue,
                       mParticleId: KeyPresence = .defaultValue,
                       networkID: KeyPresence = .notPresent,
                       ip: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [:]

        function(keyPresence: idfa, data: &data, key: AttributionKey.idfa.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfa)
        function(keyPresence: idfv, data: &data, key: AttributionKey.idfv.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfv)
        function(keyPresence: mParticleId, data: &data, key: AttributionKey.MParticle.id.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultNetworkId)
        function(keyPresence: networkID, data: &data, key: AttributionKey.networkID.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultRCNetworkId)
        function(keyPresence: ip, data: &data, key: AttributionKey.ip.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIp)
        return data
    }

    func facebookOrTenjinData(withIDFA idfa: KeyPresence = .defaultValue,
                              idfv: KeyPresence = .defaultValue, ip: KeyPresence = .defaultValue) -> [String: Any] {
        var data: [String: Any] = [:]
        function(keyPresence: idfa, data: &data, key: AttributionKey.idfa.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfa)
        function(keyPresence: idfv, data: &data, key: AttributionKey.idfv.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIdfv)
        function(keyPresence: ip, data: &data, key: AttributionKey.ip.rawValue,
                defaultValue: AttributionDataMigratorTests.defaultIp)
        return data
    }

    private func function(keyPresence: KeyPresence, data: inout [String: Any], key: String, defaultValue: String) {
        switch keyPresence {
        case .defaultValue:
            data[key] = defaultValue
        case .nsNull:
            data[key] = NSNull()
        case .notPresent:
            break
        }
    }
}
