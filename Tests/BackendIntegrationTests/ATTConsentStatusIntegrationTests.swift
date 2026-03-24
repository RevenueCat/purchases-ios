//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ATTConsentStatusIntegrationTests.swift
//

@testable import RevenueCat

import Nimble
import XCTest

class ATTConsentStatusIntegrationTests: BaseStoreKitIntegrationTests {

    private var attribution: Attribution!
    private var userID: String!
    private var syncedAttributes: [(userID: String, attributes: [String: String])] = []

    private static let attKey = ReservedSubscriberAttribute.consentStatus.rawValue

    @MainActor
    override func setUp() {
        super.setUp()

        self.attribution = Purchases.shared.attribution
        self.attribution.delegate = self

        self.userID = Purchases.shared.appUserID
        self.syncedAttributes = []
    }

    // MARK: - ATT consent status syncing

    func testATTConsentStatusIsSyncedOnFirstSync() async throws {
        let errors = try await self.syncAttributes()

        self.verifyNoErrors(errors)
        self.verifyATTSynced(forUserID: self.userID, expectedValue: "notDetermined")
    }

    func testATTConsentStatusIsNotResyncdWhenUnchanged() async throws {
        // First sync: ATT gets synced
        _ = try await self.syncAttributes()
        let firstSyncCount = self.attSyncCount(forUserID: self.userID)
        expect(firstSyncCount) >= 1

        self.syncedAttributes = []

        // Second sync: ATT should not sync again (value unchanged)
        _ = try await self.syncAttributes()
        expect(self.attSyncCount(forUserID: self.userID)) == 0
    }

    func testATTConsentStatusIsSyncedForNewUserAfterLogIn() async throws {
        // Flush ATT for initial user
        _ = try await self.syncAttributes()
        self.syncedAttributes = []

        let newUserID = UUID().uuidString
        _ = try await self.purchases.logIn(newUserID)

        let errors = try await self.syncAttributes()
        self.verifyNoErrors(errors)
        self.verifyATTSynced(forUserID: newUserID, expectedValue: "notDetermined")
    }

    func testATTConsentStatusIsSyncedForNewUserAfterLogOut() async throws {
        let user = UUID().uuidString
        _ = try await self.purchases.logIn(user)

        // Flush ATT for logged-in user
        _ = try await self.syncAttributes()
        self.syncedAttributes = []

        _ = try await self.purchases.logOut()

        let anonUser = try self.purchases.appUserID
        let errors = try await self.syncAttributes()
        self.verifyNoErrors(errors)
        self.verifyATTSynced(forUserID: anonUser, expectedValue: "notDetermined")
    }

    func testATTConsentStatusIsNotSyncedForNonCurrentUsers() async throws {
        let user1 = UUID().uuidString
        _ = try await self.purchases.logIn(user1)

        // Flush ATT for user1
        _ = try await self.syncAttributes()
        self.syncedAttributes = []

        let user2 = UUID().uuidString
        _ = try await self.purchases.logIn(user2)

        // ATT should only be synced for user2 (current), not re-synced for user1
        _ = try await self.syncAttributes()
        expect(self.attSyncCount(forUserID: user1)) == 0
        self.verifyATTSynced(forUserID: user2, expectedValue: "notDetermined")
    }

}

extension ATTConsentStatusIntegrationTests: AttributionDelegate {

    func attribution(didFinishSyncingAttributes attributes: SubscriberAttribute.Dictionary,
                     forUserID userID: String) {
        self.syncedAttributes.append(
            (userID: userID, attributes: attributes.mapValues { $0.value })
        )
    }

}

private extension ATTConsentStatusIntegrationTests {

    func syncAttributes() async throws -> [Error?] {
        let purchases = try self.purchases

        return await withCheckedContinuation { continuation in
            let errors: Atomic<[Error?]> = .init([])

            purchases.syncSubscriberAttributes(
                syncedAttribute: { error in errors.modify { $0.append(error) } },
                completion: { continuation.resume(returning: errors.value) }
            )
        }
    }

    func verifyNoErrors(_ errors: [Error?], file: FileString = #file, line: UInt = #line) {
        expect(file: file, line: line, errors).toNot(
            containElementSatisfying { $0 != nil },
            description: "Encountered errors: \(errors)"
        )
    }

    func verifyATTSynced(
        forUserID userID: String,
        expectedValue: String,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(file: file, line: line, self.syncedAttributes).to(
            containElementSatisfying {
                $0.userID == userID && $0.attributes[Self.attKey] == expectedValue
            },
            description: "Expected $attConsentStatus=\(expectedValue) for \(userID). "
                + "Synced: \(self.syncedAttributes)"
        )
    }

    func attSyncCount(forUserID userID: String) -> Int {
        self.syncedAttributes.filter {
            $0.userID == userID && $0.attributes[Self.attKey] != nil
        }.count
    }

}
