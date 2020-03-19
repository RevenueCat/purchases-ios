//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockSubscriberAttributesManager: RCSubscriberAttributesManager {

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

    var invokedSyncIfNeeded = false
    var invokedSyncIfNeededCount = 0
    var invokedSyncIfNeededParameters: (appUserID: String, Void)?
    var invokedSyncIfNeededParametersList = [(appUserID: String, Void)]()
    var stubbedSyncIfNeededCompletionResult: (Error?, Void)?

    override func syncIfNeeded(withAppUserID appUserID: String, completion: @escaping ((Error?) -> ())) {
        invokedSyncIfNeeded = true
        invokedSyncIfNeededCount += 1
        invokedSyncIfNeededParameters = (appUserID, ())
        invokedSyncIfNeededParametersList.append((appUserID, ()))
        if let result = stubbedSyncIfNeededCompletionResult {
            completion(result.0)
        }
    }

    var invokedUnsyncedAttributesByKey = false
    var invokedUnsyncedAttributesByKeyCount = 0
    var invokedUnsyncedAttributesByKeyParameters: (appUserID: String, Void)?
    var invokedUnsyncedAttributesByKeyParametersList = [(appUserID: String, Void)]()
    var stubbedUnsyncedAttributesByKeyResult: [String: RCSubscriberAttribute]! = [:]

    override func unsyncedAttributesByKey(forAppUserID appUserID: String) -> [String: RCSubscriberAttribute] {
        invokedUnsyncedAttributesByKey = true
        invokedUnsyncedAttributesByKeyCount += 1
        invokedUnsyncedAttributesByKeyParameters = (appUserID, ())
        invokedUnsyncedAttributesByKeyParametersList.append((appUserID, ()))
        return stubbedUnsyncedAttributesByKeyResult
    }

    var invokedMarkAttributes = false
    var invokedMarkAttributesCount = 0
    var invokedMarkAttributesParameters: (syncedAttributes: [String: RCSubscriberAttribute], appUserID: String)?
    var invokedMarkAttributesParametersList = [(syncedAttributes: [String: RCSubscriberAttribute], appUserID: String)]()

    override func markAttributes(asSynced syncedAttributes: [String: RCSubscriberAttribute],
                                 appUserID: String) {
        invokedMarkAttributes = true
        invokedMarkAttributesCount += 1
        invokedMarkAttributesParameters = (syncedAttributes, appUserID)
        invokedMarkAttributesParametersList.append((syncedAttributes, appUserID))
    }
}