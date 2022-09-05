//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

// swiftlint:disable identifier_name
// swiftlint:disable large_tuple
// swiftlint:disable line_length
class MockSubscriberAttributesManager: SubscriberAttributesManager {

    var invokedSetAttributes = false
    var invokedSetAttributesCount = 0
    var invokedSetAttributesParameters: (attributes: [String: String], appUserID: String)?
    var invokedSetAttributesParametersList = [(attributes: [String: String], appUserID: String)]()

    override func setAttributes(_ attributes: [String: String], appUserID: String) {
        invokedSetAttributes = true
        invokedSetAttributesCount += 1
        invokedSetAttributesParameters = (attributes, appUserID)
        invokedSetAttributesParametersList.append((attributes, appUserID))
    }

    var invokedSetEmail = false
    var invokedSetEmailCount = 0
    var invokedSetEmailParameters: (email: String?, appUserID: String)?
    var invokedSetEmailParametersList = [(email: String?, appUserID: String)]()

    override func setEmail(_ email: String?, appUserID: String) {
        invokedSetEmail = true
        invokedSetEmailCount += 1
        invokedSetEmailParameters = (email, appUserID)
        invokedSetEmailParametersList.append((email, appUserID))
    }

    var invokedSetPhoneNumber = false
    var invokedSetPhoneNumberCount = 0
    var invokedSetPhoneNumberParameters: (phoneNumber: String?, appUserID: String)?
    var invokedSetPhoneNumberParametersList = [(phoneNumber: String?, appUserID: String)]()

    override func setPhoneNumber(_ phoneNumber: String?, appUserID: String) {
        invokedSetPhoneNumber = true
        invokedSetPhoneNumberCount += 1
        invokedSetPhoneNumberParameters = (phoneNumber, appUserID)
        invokedSetPhoneNumberParametersList.append((phoneNumber, appUserID))
    }

    var invokedSetDisplayName = false
    var invokedSetDisplayNameCount = 0
    var invokedSetDisplayNameParameters: (displayName: String?, appUserID: String)?
    var invokedSetDisplayNameParametersList = [(displayName: String?, appUserID: String)]()

    override func setDisplayName(_ displayName: String?, appUserID: String) {
        invokedSetDisplayName = true
        invokedSetDisplayNameCount += 1
        invokedSetDisplayNameParameters = (displayName, appUserID)
        invokedSetDisplayNameParametersList.append((displayName, appUserID))
    }

    var invokedSetPushToken = false
    var invokedSetPushTokenCount = 0
    var invokedSetPushTokenParameters: (pushToken: Data?, appUserID: String)?
    var invokedSetPushTokenParametersList = [(pushToken: Data?, appUserID: String)]()

    override func setPushToken(_ pushToken: Data?, appUserID: String) {
        invokedSetPushToken = true
        invokedSetPushTokenCount += 1
        invokedSetPushTokenParameters = (pushToken, appUserID)
        invokedSetPushTokenParametersList.append((pushToken, appUserID))
    }

    var invokedSetPushTokenString = false
    var invokedSetPushTokenStringCount = 0
    var invokedSetPushTokenStringParameters: (pushToken: String?, appUserID: String?)?
    var invokedSetPushTokenStringParametersList = [(pushToken: String?, appUserID: String?)]()

    override func setPushTokenString(_ pushToken: String?, appUserID: String?) {
        invokedSetPushTokenString = true
        invokedSetPushTokenStringCount += 1
        invokedSetPushTokenStringParameters = (pushToken, appUserID)
        invokedSetPushTokenStringParametersList.append((pushToken, appUserID))
    }

    var invokedSetAdjustID = false
    var invokedSetAdjustIDCount = 0
    var invokedSetAdjustIDParameters: (adjustID: String?, appUserID: String?)?
    var invokedSetAdjustIDParametersList = [(pushToken: String?, appUserID: String?)]()

    override func setAdjustID(_ adjustID: String?, appUserID: String) {
        invokedSetAdjustID = true
        invokedSetAdjustIDCount += 1
        invokedSetAdjustIDParameters = (adjustID, appUserID)
        invokedSetAdjustIDParametersList.append((adjustID, appUserID))
    }

    var invokedSetAppsflyerID = false
    var invokedSetAppsflyerIDCount = 0
    var invokedSetAppsflyerIDParameters: (appsflyerID: String?, appUserID: String?)?
    var invokedSetAppsflyerIDParametersList = [(appsflyerID: String?, appUserID: String?)]()

    override func setAppsflyerID(_ appsflyerID: String?, appUserID: String) {
        invokedSetAppsflyerID = true
        invokedSetAppsflyerIDCount += 1
        invokedSetAppsflyerIDParameters = (appsflyerID, appUserID)
        invokedSetAppsflyerIDParametersList.append((appsflyerID, appUserID))
    }

    var invokedSetFBAnonymousID = false
    var invokedSetFBAnonymousIDCount = 0
    var invokedSetFBAnonymousIDParameters: (fbAnonymousID: String?, appUserID: String?)?
    var invokedSetFBAnonymousIDParametersList = [(fbAnonymousID: String?, appUserID: String?)]()

    override func setFBAnonymousID(_ fbAnonymousID: String?, appUserID: String) {
        invokedSetFBAnonymousID = true
        invokedSetFBAnonymousIDCount += 1
        invokedSetFBAnonymousIDParameters = (fbAnonymousID, appUserID)
        invokedSetFBAnonymousIDParametersList.append((fbAnonymousID, appUserID))
    }

    var invokedSetMparticleID = false
    var invokedSetMparticleIDCount = 0
    var invokedSetMparticleIDParameters: (mparticleID: String?, appUserID: String?)?
    var invokedSetMparticleIDParametersList = [(mparticleID: String?, appUserID: String?)]()

    override func setMparticleID(_ mparticleID: String?, appUserID: String) {
        invokedSetMparticleID = true
        invokedSetMparticleIDCount += 1
        invokedSetMparticleIDParameters = (mparticleID, appUserID)
        invokedSetMparticleIDParametersList.append((mparticleID, appUserID))
    }

    var invokedSetOnesignalID = false
    var invokedSetOnesignalIDCount = 0
    var invokedSetOnesignalIDParameters: (onesignalID: String?, appUserID: String?)?
    var invokedSetOnesignalIDParametersList = [(onesignalID: String?, appUserID: String?)]()

    override func setOnesignalID(_ onesignalID: String?, appUserID: String) {
        invokedSetOnesignalID = true
        invokedSetOnesignalIDCount += 1
        invokedSetOnesignalIDParameters = (onesignalID, appUserID)
        invokedSetOnesignalIDParametersList.append((onesignalID, appUserID))
    }

    var invokedSetAirshipChannelID = false
    var invokedSetAirshipChannelIDCount = 0
    var invokedSetAirshipChannelIDParameters: (airshipChannelID: String?, appUserID: String?)?
    var invokedSetAirshipChannelIDParametersList = [(airshipChannelID: String?, appUserID: String?)]()

    override func setAirshipChannelID(_ airshipChannelID: String?, appUserID: String) {
        invokedSetAirshipChannelID = true
        invokedSetAirshipChannelIDCount += 1
        invokedSetAirshipChannelIDParameters = (airshipChannelID, appUserID)
        invokedSetAirshipChannelIDParametersList.append((airshipChannelID, appUserID))
    }

    var invokedSetCleverTapID = false
    var invokedSetCleverTapIDCount = 0
    var invokedSetCleverTapIDParameters: (CleverTapID: String?, appUserID: String?)?
    var invokedSetCleverTapIDParametersList = [(CleverTapID: String?, appUserID: String?)]()

    override func setCleverTapID(_ cleverTapID: String?, appUserID: String) {
        invokedSetCleverTapID = true
        invokedSetCleverTapIDCount += 1
        invokedSetCleverTapIDParameters = (cleverTapID, appUserID)
        invokedSetCleverTapIDParametersList.append((cleverTapID, appUserID))
    }

    var invokedSetMixpanelDistinctID = false
    var invokedSetMixpanelDistinctIDCount = 0
    var invokedSetMixpanelDistinctIDParameters: (mixpanelDistinctID: String?, appUserID: String?)?
    var invokedSetMixpanelDistinctIDParametersList = [(mixpanelDistinctID: String?, appUserID: String?)]()

    override func setMixpanelDistinctID(_ mixpanelDistinctID: String?, appUserID: String) {
        invokedSetMixpanelDistinctID = true
        invokedSetMixpanelDistinctIDCount += 1
        invokedSetMixpanelDistinctIDParameters = (mixpanelDistinctID, appUserID)
        invokedSetMixpanelDistinctIDParametersList.append((mixpanelDistinctID, appUserID))
    }

    var invokedSetFirebaseAppInstanceID = false
    var invokedSetFirebaseAppInstanceIDCount = 0
    var invokedSetFirebaseAppInstanceIDParameters: (firebaseAppInstanceID: String?, appUserID: String?)?
    var invokedSetFirebaseAppInstanceIDParametersList = [(firebaseAppInstanceID: String?, appUserID: String?)]()

    override func setFirebaseAppInstanceID(_ firebaseAppInstanceID: String?, appUserID: String) {
        invokedSetFirebaseAppInstanceID = true
        invokedSetFirebaseAppInstanceIDCount += 1
        invokedSetFirebaseAppInstanceIDParameters = (firebaseAppInstanceID, appUserID)
        invokedSetFirebaseAppInstanceIDParametersList.append((firebaseAppInstanceID, appUserID))
    }

    var invokedSetMediaSource = false
    var invokedSetMediaSourceCount = 0
    var invokedSetMediaSourceParameters: (mediaSource: String?, appUserID: String?)?
    var invokedSetMediaSourceParametersList = [(mediaSource: String?, appUserID: String?)]()

    override func setMediaSource(_ mediaSource: String?, appUserID: String) {
        invokedSetMediaSource = true
        invokedSetMediaSourceCount += 1
        invokedSetMediaSourceParameters = (mediaSource, appUserID)
        invokedSetMediaSourceParametersList.append((mediaSource, appUserID))
    }

    var invokedSetCampaign = false
    var invokedSetCampaignCount = 0
    var invokedSetCampaignParameters: (campaign: String?, appUserID: String?)?
    var invokedSetCampaignParametersList = [(campaign: String?, appUserID: String?)]()

    override func setCampaign(_ campaign: String?, appUserID: String) {
        invokedSetCampaign = true
        invokedSetCampaignCount += 1
        invokedSetCampaignParameters = (campaign, appUserID)
        invokedSetCampaignParametersList.append((campaign, appUserID))
    }

    var invokedSetAdGroup = false
    var invokedSetAdGroupCount = 0
    var invokedSetAdGroupParameters: (adGroup: String?, appUserID: String?)?
    var invokedSetAdGroupParametersList = [(adGroup: String?, appUserID: String?)]()

    override func setAdGroup(_ adGroup: String?, appUserID: String) {
        invokedSetAdGroup = true
        invokedSetAdGroupCount += 1
        invokedSetAdGroupParameters = (adGroup, appUserID)
        invokedSetAdGroupParametersList.append((adGroup, appUserID))
    }

    var invokedSetAd = false
    var invokedSetAdCount = 0
    var invokedSetAdParameters: (ad: String?, appUserID: String?)?
    var invokedSetAdParametersList = [(ad: String?, appUserID: String?)]()

    override func setAd(_ ad: String?, appUserID: String) {
        invokedSetAd = true
        invokedSetAdCount += 1
        invokedSetAdParameters = (ad, appUserID)
        invokedSetAdParametersList.append((ad, appUserID))
    }

    var invokedSetKeyword = false
    var invokedSetKeywordCount = 0
    var invokedSetKeywordParameters: (keyword: String?, appUserID: String?)?
    var invokedSetKeywordParametersList = [(keyword: String?, appUserID: String?)]()

    override func setKeyword(_ keyword: String?, appUserID: String) {
        invokedSetKeyword = true
        invokedSetKeywordCount += 1
        invokedSetKeywordParameters = (keyword, appUserID)
        invokedSetKeywordParametersList.append((keyword, appUserID))
    }

    var invokedSetCreative = false
    var invokedSetCreativeCount = 0
    var invokedSetCreativeParameters: (creative: String?, appUserID: String?)?
    var invokedSetCreativeParametersList = [(creative: String?, appUserID: String?)]()

    override func setCreative(_ creative: String?, appUserID: String) {
        invokedSetCreative = true
        invokedSetCreativeCount += 1
        invokedSetCreativeParameters = (creative, appUserID)
        invokedSetCreativeParametersList.append((creative, appUserID))
    }

    var invokedUnsyncedAttributesByKey = false
    var invokedUnsyncedAttributesByKeyCount = 0
    var invokedUnsyncedAttributesByKeyParameters: (appUserID: String, Void)?
    var invokedUnsyncedAttributesByKeyParametersList = [(appUserID: String, Void)]()
    var stubbedUnsyncedAttributesByKeyResult: [String: SubscriberAttribute]! = [:]

    override func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        invokedUnsyncedAttributesByKey = true
        invokedUnsyncedAttributesByKeyCount += 1
        invokedUnsyncedAttributesByKeyParameters = (appUserID, ())
        invokedUnsyncedAttributesByKeyParametersList.append((appUserID, ()))
        return stubbedUnsyncedAttributesByKeyResult
    }

    var invokedMarkAttributes = false
    var invokedMarkAttributesCount = 0
    var invokedMarkAttributesParameters: (syncedAttributes: [String: SubscriberAttribute]?, appUserID: String)?
    var invokedMarkAttributesParametersList = [(syncedAttributes: [String: SubscriberAttribute]?, appUserID: String)]()

    override func markAttributesAsSynced(_ syncedAttributes: [String: SubscriberAttribute]?,
                                         appUserID: String) {
        invokedMarkAttributes = true
        invokedMarkAttributesCount += 1
        invokedMarkAttributesParameters = (syncedAttributes, appUserID)
        invokedMarkAttributesParametersList.append((syncedAttributes, appUserID))
    }

    var invokedSyncAttributesForAllUsers = false
    var invokedSyncAttributesForAllUsersCount = 0
    var invokedSyncAttributesForAllUsersParameters: (currentAppUserID: String?, Void)?
    var invokedSyncAttributesForAllUsersParametersList = [(currentAppUserID: String?, Void)]()

    override func syncAttributesForAllUsers(
        currentAppUserID: String,
        syncedAttribute: (@Sendable (PurchasesError?) -> Void)? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> Int {
        invokedSyncAttributesForAllUsers = true
        invokedSyncAttributesForAllUsersCount += 1
        invokedSyncAttributesForAllUsersParameters = (currentAppUserID, ())
        invokedSyncAttributesForAllUsersParametersList.append((currentAppUserID, ()))

        return -1
    }

    var invokedCollectDeviceIdentifiers = false
    var invokedCollectDeviceIdentifiersCount = 0
    var invokedCollectDeviceIdentifiersParameters: (appUserID: String?, Void)?
    var invokedCollectDeviceIdentifiersParametersList = [(appUserID: String?, Void)]()

    override func collectDeviceIdentifiers(forAppUserID appUserID: String) {
        invokedCollectDeviceIdentifiers = true
        invokedCollectDeviceIdentifiersCount += 1
        invokedCollectDeviceIdentifiersParameters = (appUserID, ())
        invokedCollectDeviceIdentifiersParametersList.append((appUserID, ()))
    }

    var invokedConvertAttributionDataAndSet = false
    var invokedConvertAttributionDataAndSetCount = 0
    var invokedConvertAttributionDataAndSetParameters: (attributionData: [String: Any], network: AttributionNetwork, appUserID: String)?
    var invokedConvertAttributionDataAndSetParametersList = [(attributionData: [String: Any], network: AttributionNetwork, appUserID: String)]()

    override func setAttributes(fromAttributionData attributionData: [String: Any],
                                network: AttributionNetwork,
                                appUserID: String) {
        invokedConvertAttributionDataAndSet = true
        invokedConvertAttributionDataAndSetCount += 1
        invokedConvertAttributionDataAndSetParameters = (attributionData, network, appUserID)
        invokedConvertAttributionDataAndSetParametersList.append((attributionData, network, appUserID))
    }

}
