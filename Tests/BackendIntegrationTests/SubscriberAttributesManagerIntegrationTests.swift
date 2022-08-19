//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesManagerIntegrationTests.swift
//
//  Created by Nacho Soto on 4/1/22.

@testable import RevenueCat

import Nimble
import XCTest

// swiftlint:disable:next type_name
class SubscriberAttributesManagerIntegrationTests: BaseBackendIntegrationTests {

    private var attribution: Attribution!
    private var userID: String!
    private var syncedAttributes: [(userID: String, attributes: [String: String])] = []

    private static let testEmail = "test@revenuecat.com"

    override func setUp() {
        super.setUp()

        self.attribution = Purchases.shared.attribution
        self.attribution.delegate = self

        self.userID = Purchases.shared.appUserID
        self.syncedAttributes = []
    }

    // MARK: -

    func testNothingToSync() {
        expect(Purchases.shared.syncSubscriberAttributes()) == 0
    }

    func testSyncOneAttribute() async throws {
        self.attribution.setEmail(Self.testEmail)

        let errors = await self.syncAttributes()

        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(self.userID, [reserved(.email): Self.testEmail])
    }

    func testSettingTheSameAttributeDoesNotNeedToChangeIt() async throws {
        self.attribution.setEmail(Self.testEmail)

        var errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(self.userID, [reserved(.email): Self.testEmail])

        self.attribution.setEmail(Self.testEmail)
        errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 0)
        expect(self.syncedAttributes)
            .to(
                haveCount(1),
                description: "Attribute should not have synced again"
            )
    }

    func testChangingEmailSyncsIt() async throws {
        self.attribution.setEmail(Self.testEmail)

        var errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(self.userID, [reserved(.email): Self.testEmail])

        let newEmail = "test2@revenuecat.com"

        self.attribution.setEmail(newEmail)
        errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(self.userID, [reserved(.email): newEmail])
    }

    func testSyncInvalidEmail() async throws {
        let invalidEmail = "invalid @ email @.com"

        self.attribution.setEmail(invalidEmail)

        let errors = await self.syncAttributes()
        let error = try XCTUnwrap(errors.onlyElement ?? nil) as NSError

        self.verifySyncedAttribute(self.userID, [reserved(.email): invalidEmail])

        expect(error.domain) == RCPurchasesErrorCodeDomain
        expect(error.code) == ErrorCode.invalidSubscriberAttributesError.rawValue
        expect(error.subscriberAttributesErrors) == [
            "$email": "Email address is not a valid email."
        ]
    }

    func testLogInGetsNewAttributes() async throws {
        self.attribution.setEmail(Self.testEmail)

        var errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)

        self.verifySyncedAttribute(self.userID, [reserved(.email): Self.testEmail])

        let newUserID = UUID().uuidString
        _ = try await Purchases.shared.logIn(newUserID)

        self.attribution.setEmail(Self.testEmail)

        errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(newUserID, [reserved(.email): Self.testEmail])
    }

    func testPushTokenWithInvalidTokenDoesNotFail() async throws {
        let token = "invalid token".asData

        self.attribution.setPushToken(token)

        let errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(self.userID, [reserved(.pushToken): token.asString])
    }

    func testSetCustomAttributes() async throws {
        let attributes = [
            "custom_key": "random value",
            "locale": Locale.current.identifier
        ]

        self.attribution.setAttributes(attributes)

        let errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1) // 1 user with 2 attributes
        self.verifySyncedAttribute(self.userID, attributes)
    }

    func testSetMultipleAttributes() async throws {
        let name = "Tom Hanks"
        let phone = "4157689215"

        self.attribution.setDisplayName(name)
        self.attribution.setPhoneNumber(phone)

        let errors = await self.syncAttributes()

        // 1 user with 2 attributes:
        self.verifyAttributesSyncedWithNoErrors(errors, 1)

        // 1 request with 2 attributes:
        self.verifySyncedAttribute(self.userID, [
            reserved(.displayName): name,
            reserved(.phoneNumber): phone
        ])
    }

    func testLogInPostsUnsyncedAttributes() async throws {
        let user1 = UUID().uuidString
        let name1 = "User 1"
        let user2 = UUID().uuidString
        let name2 = "User 2"

        _ = try await Purchases.shared.logIn(user1)
        self.attribution.setDisplayName(name1)

        _ = try await Purchases.shared.logIn(user2)
        // Log in forced previous unsynced attributes to be synced
        self.verifySyncedAttribute(user1, [reserved(.displayName): name1])

        self.attribution.setDisplayName(name2)

        let errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(user2, [reserved(.displayName): name2])
    }

    func testLogOutPostsUnsyncedAttributes() async throws {
        let user = UUID().uuidString
        let name = "User 1"

        _ = try await Purchases.shared.logIn(user)
        expect(Purchases.shared.isAnonymous) == false

        self.attribution.setDisplayName(name)

        _ = try await Purchases.shared.logOut()
        expect(Purchases.shared.isAnonymous) == true

        // Log out should post unsynced attributes
        self.verifySyncedAttribute(user, [reserved(.displayName): name])

        let anonUser = Purchases.shared.appUserID
        let anonName = "User 2"

        expect(anonUser) != user

        self.attribution.setDisplayName(anonName)

        let errors = await self.syncAttributes()
        self.verifyAttributesSyncedWithNoErrors(errors, 1)
        self.verifySyncedAttribute(anonUser, [reserved(.displayName): anonName])
    }

}

extension SubscriberAttributesManagerIntegrationTests: AttributionDelegate {

    func attribution(didFinishSyncingAttributes attributes: SubscriberAttribute.Dictionary,
                     forUserID userID: String) {
        self.syncedAttributes.append(
            (userID: userID, attributes: attributes.mapValues { $0.value })
        )
    }

}

private extension SubscriberAttributesManagerIntegrationTests {

    func reserved(_ attribute: ReservedSubscriberAttribute) -> String {
        return attribute.rawValue
    }

    func syncAttributes() async -> [Error?] {
        return await withCheckedContinuation { continuation in
            var errors: [Error?] = []

            Purchases.shared.syncSubscriberAttributes(
                syncedAttribute: { errors.append($0) },
                completion: { continuation.resume(returning: errors) }
            )
        }
    }

    private func verifyAttributesSyncedWithNoErrors(
        _ errors: [Error?],
        _ expectedCount: Int,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            errors
        ).to(
            haveCount(expectedCount),
            description: "Incorrect number of attributes"
        )
        expect(
            file: file, line: line,
            errors
        ).toNot(
            containElementSatisfying { $0 != nil },
            description: "Encountered errors: \(errors)"
        )
    }

    private func verifySyncedAttribute(
        _ userID: String,
        _ attributes: [String: String],
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            self.syncedAttributes
        ).to(
            containElementSatisfying {
                $0.userID == userID && $0.attributes == attributes
            },
            description: "Attribute request not found. Synced attributes: \(self.syncedAttributes)"
        )
    }

}
