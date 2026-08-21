//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSecureItemStorage.swift
//
//  Created by RevenueCat on 8/13/26.

import Foundation

@testable import RevenueCat

/// An in-memory fake of ``SecureItemStorage``, used so that tests exercising code that reads/writes
/// secure items (e.g. ``TokenManager``) don't need to touch the real system Keychain.
///
/// `storedItems` is exposed directly so tests can seed or inspect state without going through
/// `saveItem`/`deleteItem`, and `errorToThrow`, when set, makes every operation throw instead of
/// performing its normal behavior.
final class MockSecureItemStorage: SecureItemStorage {

    var storedItems: [String: Data] = [:]
    var errorToThrow: SecureStorageError?

    private(set) var invokedReadItemIdentifiers: [String] = []

    private(set) var saveCallCount = 0
    private(set) var invokedSaveItemIdentifiers: [String] = []
    private(set) var lastSaveIdentifier: String?
    private(set) var lastSaveContents: Data?
    private(set) var lastSaveAttributes: SecureItemAttributes?

    private(set) var deleteCallCount = 0
    private(set) var invokedDeleteItemIdentifiers: [String] = []
    private(set) var lastDeleteIdentifier: String?

    func allItemIdentifiers() throws -> [String] {
        if let errorToThrow { throw errorToThrow }
        return Array(self.storedItems.keys)
    }

    func readItem(identifier: String) throws -> Data? {
        if let errorToThrow { throw errorToThrow }
        self.invokedReadItemIdentifiers.append(identifier)
        return self.storedItems[identifier]
    }

    func saveItem(identifier: String, contents: Data, attributes: SecureItemAttributes) throws {
        if let errorToThrow { throw errorToThrow }
        self.saveCallCount += 1
        self.invokedSaveItemIdentifiers.append(identifier)
        self.lastSaveIdentifier = identifier
        self.lastSaveContents = contents
        self.lastSaveAttributes = attributes
        self.storedItems[identifier] = contents
    }

    func deleteItem(identifier: String) throws {
        if let errorToThrow { throw errorToThrow }
        self.deleteCallCount += 1
        self.invokedDeleteItemIdentifiers.append(identifier)
        self.lastDeleteIdentifier = identifier
        self.storedItems.removeValue(forKey: identifier)
    }

}
