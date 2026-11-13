//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  KeychainDPoPStrategyTests.swift
//
//  Created by Dave DeLong on 11/10/26.

import Foundation
import Nimble
import Security
import XCTest

@testable import RevenueCat

class KeychainDPoPStrategyTests: TestCase {

    private var storage: MockSecureItemStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.storage = MockSecureItemStorage()
    }

    // MARK: - Creating keys

    func testStoresANewKeyExcludedFromBackups() throws {
        _ = try KeychainDPoPStrategy(storage: self.storage).publicKey()

        expect(self.storage.storedItems[KeychainDPoPStrategy.storageIdentifier]).toNot(beNil())
        expect(self.storage.lastAddAttributes?.includedInBackup) == false
    }

    func testHasStoredKeyIsFalseUntilAKeyIsCreated() throws {
        let strategy = KeychainDPoPStrategy(storage: self.storage)
        expect(strategy.hasStoredKey) == false

        _ = try strategy.publicKey()

        expect(strategy.hasStoredKey) == true
    }

    func testThrowsWhenTheKeyCannotBeStored() {
        self.storage.errorToThrow = SecureStorageError(rawValue: errSecNotAvailable)

        expect { try KeychainDPoPStrategy(storage: self.storage).publicKey() }.to(throwError())
    }

    // MARK: - Reusing keys

    func testReusesTheSameKey() throws {
        let strategy = KeychainDPoPStrategy(storage: self.storage)

        let first = try strategy.publicKey()
        let second = try strategy.publicKey()

        expect(second.rawRepresentation) == first.rawRepresentation
        expect(self.storage.addCallCount) == 1
    }

    func testRestoresTheStoredKey() throws {
        let original = try KeychainDPoPStrategy(storage: self.storage).publicKey()

        let restored = try KeychainDPoPStrategy(storage: self.storage).publicKey()

        expect(restored.rawRepresentation) == original.rawRepresentation
        expect(self.storage.addCallCount) == 1
    }

    func testUsesTheKeyStoredByAnotherProcessWhenItIsStoredFirst() throws {
        // another process (e.g. an app extension) stores its key between our read and our add
        let otherProcessStorage = MockSecureItemStorage()
        let otherProcessKey = try KeychainDPoPStrategy(storage: otherProcessStorage).publicKey()
        let racingStorage = RacingSecureItemStorage(
            wrapped: self.storage,
            itemStoredByOtherProcess: try XCTUnwrap(
                otherProcessStorage.storedItems[KeychainDPoPStrategy.storageIdentifier]
            )
        )

        let key = try KeychainDPoPStrategy(storage: racingStorage).publicKey()

        expect(key.rawRepresentation) == otherProcessKey.rawRepresentation
    }

    // MARK: - Unusable keys

    func testReplacesAStoredKeyThatCannotBeRestored() throws {
        self.storage.storedItems[KeychainDPoPStrategy.storageIdentifier] = Data("not a key".utf8)

        let key = try KeychainDPoPStrategy(storage: self.storage).publicKey()

        let restored = try KeychainDPoPStrategy(storage: self.storage).publicKey()
        expect(restored.rawRepresentation) == key.rawRepresentation
    }

}

/// Simulates another process storing its key after our first read finds nothing, but before our add.
private final class RacingSecureItemStorage: SecureItemStorage {

    private let wrapped: MockSecureItemStorage
    private let itemStoredByOtherProcess: Data

    init(wrapped: MockSecureItemStorage, itemStoredByOtherProcess: Data) {
        self.wrapped = wrapped
        self.itemStoredByOtherProcess = itemStoredByOtherProcess
    }

    func allItemIdentifiers() throws -> [String] {
        return try self.wrapped.allItemIdentifiers()
    }

    func readItem(identifier: String) throws -> Data? {
        return try self.wrapped.readItem(identifier: identifier)
    }

    func saveItem(identifier: String, contents: Data, attributes: SecureItemAttributes) throws {
        try self.wrapped.saveItem(identifier: identifier, contents: contents, attributes: attributes)
    }

    func addItem(identifier: String, contents: Data, attributes: SecureItemAttributes) throws -> Bool {
        if self.wrapped.storedItems[identifier] == nil {
            self.wrapped.storedItems[identifier] = self.itemStoredByOtherProcess
        }
        return try self.wrapped.addItem(identifier: identifier, contents: contents, attributes: attributes)
    }

    func deleteItem(identifier: String) throws {
        try self.wrapped.deleteItem(identifier: identifier)
    }

}
