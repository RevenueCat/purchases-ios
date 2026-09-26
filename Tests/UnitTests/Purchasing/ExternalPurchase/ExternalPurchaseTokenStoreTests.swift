//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenStoreTests.swift
//
//  Created by Antonio Pallares on 10/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ExternalPurchaseTokenStoreTests: TestCase {

    private static let registration = ExternalPurchaseTokenRegistration(
        tokenID: "ept13dcbc01adaa44db9b1691a6be2f9929",
        appUserID: "test-app-user-id",
        purchaseType: .linkOut,
        token: "test-external-purchase-token"
    )

    private static let otherRegistration = ExternalPurchaseTokenRegistration(
        tokenID: "epta51d06bc57f344ffb386dff7e2353bea",
        appUserID: "test-app-user-id",
        purchaseType: .linkOut,
        token: "another-external-purchase-token"
    )

    private var cache: MockLargeItemCache!
    private var store: ExternalPurchaseTokenStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.cache = MockLargeItemCache()
        self.store = ExternalPurchaseTokenStore(apiKey: "test_api_key", fileManager: self.cache)
    }

    /// A registration has to outlive the app being killed, so it goes to a directory the system does not
    /// reclaim, other than on tvOS where there is none.
    func testKeepsRegistrationsOutsideTheCacheDirectory() throws {
        let invocation = try XCTUnwrap(self.cache.createDirectoryInvocations.first)

        switch invocation.directoryType {
        #if os(tvOS)
        case .cache:
            break
        #else
        case .applicationSupport:
            break
        #endif
        default:
            fail("Unexpected directory type: \(invocation.directoryType)")
        }
    }

    func testStoresEveryFieldTheRegistrationNeeds() throws {
        self.store.store(Self.registration)

        let saved = try XCTUnwrap(self.cache.saveDataInvocations.onlyElement)
        let decoded = try JSONDecoder.default.decode(ExternalPurchaseTokenRegistration.self, from: saved.data)

        expect(decoded) == Self.registration
    }

    /// Where StoreKit had no token to give, the registration still has to be kept: the backend generates a
    /// token for it.
    func testStoresARegistrationThatCarriesNoToken() throws {
        let registration = ExternalPurchaseTokenRegistration(
            tokenID: "ept13dcbc01adaa44db9b1691a6be2f9929",
            appUserID: "test-app-user-id",
            purchaseType: .inApp,
            token: nil
        )

        self.store.store(registration)

        let saved = try XCTUnwrap(self.cache.saveDataInvocations.onlyElement)
        let decoded = try JSONDecoder.default.decode(ExternalPurchaseTokenRegistration.self, from: saved.data)

        expect(decoded) == registration
    }

    func testFilesARegistrationUnderItsOwnIdentifier() throws {
        self.store.store(Self.registration)

        let saved = try XCTUnwrap(self.cache.saveDataInvocations.onlyElement)

        expect(saved.url.lastPathComponent)
            == "external_purchase_token_registration_\(Self.registration.tokenID)"
    }

    func testRemovesTheRegistrationItStored() throws {
        self.store.store(Self.registration)
        self.store.remove(Self.registration)

        let saved = try XCTUnwrap(self.cache.saveDataInvocations.onlyElement)
        let removed = try XCTUnwrap(self.cache.removeInvocations.onlyElement)

        expect(removed) == saved.url
    }

    func testKeepsTheOtherRegistrationsWhenOneIsRemoved() throws {
        self.store.store(Self.registration)
        self.store.store(Self.otherRegistration)
        self.store.remove(Self.registration)

        let removed = try XCTUnwrap(self.cache.removeInvocations.onlyElement)

        expect(removed.lastPathComponent).to(contain(Self.registration.tokenID))
        expect(removed.lastPathComponent).toNot(contain(Self.otherRegistration.tokenID))
    }

    func testReadsBackEveryRegistrationItKept() {
        self.store.store(Self.registration)
        self.store.store(Self.otherRegistration)

        let registrations = self.store.allRegistrations()

        expect(registrations).to(haveCount(2))
        expect(registrations).to(contain(Self.registration))
        expect(registrations).to(contain(Self.otherRegistration))
    }

    func testReadsBackNothingWhenNothingWasKept() {
        expect(self.store.allRegistrations()).to(beEmpty())
    }

    func testDoesNotReadBackARegistrationItRemoved() {
        self.store.store(Self.registration)
        self.store.store(Self.otherRegistration)
        self.store.remove(Self.registration)

        expect(self.store.allRegistrations()) == [Self.otherRegistration]
    }

    /// A registration that cannot be read can never be posted, so it is dropped rather than kept forever.
    func testDropsARegistrationItCannotRead() throws {
        self.store.store(Self.registration)

        let saved = try XCTUnwrap(self.cache.saveDataInvocations.onlyElement)
        try self.cache.saveData(Data("not a registration".utf8), to: saved.url)

        expect(self.store.allRegistrations()).to(beEmpty())
        expect(self.cache.removeInvocations) == [saved.url]
    }

}
