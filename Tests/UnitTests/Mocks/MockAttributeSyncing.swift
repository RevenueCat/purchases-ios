//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAttributeSyncing.swift
//
//  Created by Nacho Soto on 6/19/22.

@testable import RevenueCat

class MockAttributeSyncing: AttributeSyncing {

    var invokedSyncAttributes = false
    var invokedSyncAttributesCount = 0
    var invokedSyncAttributesUserIDs: [String] = []

    func syncSubscriberAttributes(currentAppUserID: String, completion: @escaping @Sendable () -> Void) {
        self.invokedSyncAttributes = true
        self.invokedSyncAttributesCount += 1
        self.invokedSyncAttributesUserIDs.append(currentAppUserID)

        completion()
    }

    var invokedStoreAttributesParametersList: [(attributes: [String: String], appUserID: String)] = []
    var stubbedStoredAttributes: SubscriberAttribute.Dictionary?

    @discardableResult
    func store(attributes: [String: String], appUserID: String) -> SubscriberAttribute.Dictionary {
        self.invokedStoreAttributesParametersList.append((attributes, appUserID))

        if let stubbedStoredAttributes = self.stubbedStoredAttributes {
            return stubbedStoredAttributes
        }

        return SubscriberAttribute.Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.key, SubscriberAttribute(withKey: $0.key, value: $0.value)) }
        )
    }

    var invokedRefreshATTStatusAndGetUnsyncedAttributesUserIDs: [String] = []
    var stubbedUnsyncedAttributes: SubscriberAttribute.Dictionary = [:]

    func refreshATTStatusAndGetUnsyncedAttributes(appUserID: String) -> SubscriberAttribute.Dictionary {
        self.invokedRefreshATTStatusAndGetUnsyncedAttributesUserIDs.append(appUserID)

        return self.stubbedUnsyncedAttributes
    }

    var invokedHandleAttributesSentOnLogInParametersList: [
        (attributes: SubscriberAttribute.Dictionary, appUserID: String, errorResponse: ErrorResponse?)
    ] = []

    func handleAttributesSentOnLogIn(_ attributes: SubscriberAttribute.Dictionary,
                                     appUserID: String,
                                     errorResponse: ErrorResponse?) {
        self.invokedHandleAttributesSentOnLogInParametersList.append((attributes, appUserID, errorResponse))
    }

}

// `AttributeSyncing` requires types to be `Sendable`.
// This type isn't, but it's only meant for testing.
extension MockAttributeSyncing: @unchecked Sendable {}
