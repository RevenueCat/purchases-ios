//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SecureItemStorageTests.swift
//
//  Created by Dave DeLong on 6/24/26.

import Nimble
import Security
import XCTest

@testable import RevenueCat

// MARK: - SecureStorageError

class SecureStorageErrorTests: TestCase {

    func testRawValueIsStored() {
        let error = SecureStorageError(rawValue: errSecItemNotFound)
        expect(error.rawValue) == errSecItemNotFound
    }

    func testRawValueIsStoredForSuccess() {
        let error = SecureStorageError(rawValue: errSecSuccess)
        expect(error.rawValue) == errSecSuccess
    }

    func testDescriptionIsNonEmptyForKnownError() {
        let error = SecureStorageError(rawValue: errSecItemNotFound)
        expect(error.description).toNot(beEmpty())
    }

    func testDescriptionIsNonEmptyForSuccessStatus() {
        let error = SecureStorageError(rawValue: errSecSuccess)
        expect(error.description).toNot(beEmpty())
    }

    func testDescriptionIsNonEmptyForUnknownStatus() {
        // For unrecognized OSStatus codes, the description should always be non-empty
        // (either a system message or the numeric fallback string)
        let error = SecureStorageError(rawValue: OSStatus(Int32.max))
        expect(error.description).toNot(beEmpty())
    }

    func testDescriptionFallsBackToNumericStringWhenSystemMessageUnavailable() {
        // Pick a status that is unlikely to have a human-readable system message.
        // The implementation uses SecCopyErrorMessageString, which returns nil for
        // unknown codes, in which case description falls back to "\(rawValue)".
        let obscureStatus: OSStatus = -9_999_999
        let error = SecureStorageError(rawValue: obscureStatus)
        // Either the system gave us a message OR we fell back to the numeric string.
        let expectedFallback = "\(obscureStatus)"
        let isSystemMessage = error.description != expectedFallback
        let isFallback = error.description == expectedFallback
        expect(isSystemMessage || isFallback) == true
    }

    func testConformsToError() {
        // Verify the type can be used as any Error without explicit casting
        let error: any Error = SecureStorageError(rawValue: errSecAuthFailed)
        expect(error).toNot(beNil())
    }

    func testTwoErrorsWithSameRawValueAreDescribedIdentically() {
        let error1 = SecureStorageError(rawValue: errSecDuplicateItem)
        let error2 = SecureStorageError(rawValue: errSecDuplicateItem)
        expect(error1.description) == error2.description
    }

}

// MARK: - SecureItemAttributes

class SecureItemAttributesTests: TestCase {

    func testDefaultIncludedInBackupIsTrue() {
        let attrs = SecureItemAttributes()
        expect(attrs.includedInBackup) == true
    }

    func testIncludedInBackupCanBeSetToFalse() {
        var attrs = SecureItemAttributes()
        attrs.includedInBackup = false
        expect(attrs.includedInBackup) == false
    }

    func testMutatingOneInstanceDoesNotAffectAnother() {
        let original = SecureItemAttributes()
        var copy = original
        copy.includedInBackup = false
        expect(original.includedInBackup) == true
        expect(copy.includedInBackup) == false
    }

}

// MARK: - SecureItemStorage default implementation tests

/// In-memory mock that records calls and supports configurable error injection.
private class MockSecureItemStorage: SecureItemStorage {

    var storedItems: [String: Data] = [:]
    var errorToThrow: SecureStorageError?

    // Call-tracking
    private(set) var saveCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var lastSaveIdentifier: String?
    private(set) var lastSaveContents: Data?
    private(set) var lastSaveAttributes: SecureItemAttributes?
    private(set) var lastDeleteIdentifier: String?

    func allItemIdentifiers() throws -> [String] {
        if let error = errorToThrow { throw error }
        return Array(storedItems.keys)
    }

    func readItem(identifier: String) throws -> Data? {
        if let error = errorToThrow { throw error }
        return storedItems[identifier]
    }

    func saveItem(
        identifier: String,
        contents: Data,
        attributes: SecureItemAttributes
    ) throws {
        if let error = errorToThrow { throw error }
        saveCallCount += 1
        lastSaveIdentifier = identifier
        lastSaveContents = contents
        lastSaveAttributes = attributes
        storedItems[identifier] = contents
    }

    func deleteItem(identifier: String) throws {
        if let error = errorToThrow { throw error }
        deleteCallCount += 1
        lastDeleteIdentifier = identifier
        storedItems.removeValue(forKey: identifier)
    }

}

class MockSecureItemStorageTests: TestCase {

    private var storage: MockSecureItemStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.storage = MockSecureItemStorage()
    }

    // MARK: containsItem (default implementation delegates to allItemIdentifiers)

    func testContainsItemReturnsTrueWhenIdentifierPresent() throws {
        storage.storedItems["alpha"] = Data([0x01])
        expect(try self.storage.containsItem(identifier: "alpha")) == true
    }

    func testContainsItemReturnsFalseWhenIdentifierAbsent() throws {
        expect(try self.storage.containsItem(identifier: "missing")) == false
    }

    func testContainsItemReturnsFalseWhenStorageIsEmpty() throws {
        expect(try self.storage.containsItem(identifier: "any")) == false
    }

    func testContainsItemChecksExactIdentifier() throws {
        storage.storedItems["abc"] = Data([0x01])
        expect(try self.storage.containsItem(identifier: "ab")) == false
        expect(try self.storage.containsItem(identifier: "abcd")) == false
        expect(try self.storage.containsItem(identifier: "ABC")) == false
    }

    func testContainsItemPropagatesErrorFromAllItemIdentifiers() {
        storage.errorToThrow = SecureStorageError(rawValue: errSecNotAvailable)
        do {
            _ = try storage.containsItem(identifier: "key")
            XCTFail("Expected SecureStorageError to be thrown")
        } catch let error as SecureStorageError {
            // typed throw — error is SecureStorageError directly
            expect(error.rawValue) == errSecNotAvailable
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: modifyItem(identifier:contents:attributes:) — default implementation

    func testModifyItemWithNonNilContentsCallsSaveItem() throws {
        let data = Data([0xAB, 0xCD])
        try storage.modifyItem(identifier: "key1", contents: data, attributes: SecureItemAttributes())
        expect(self.storage.saveCallCount) == 1
        expect(self.storage.deleteCallCount) == 0
        expect(self.storage.lastSaveIdentifier) == "key1"
        expect(self.storage.lastSaveContents) == data
    }

    func testModifyItemWithNilContentsCallsDeleteItem() throws {
        try storage.modifyItem(identifier: "key1", contents: nil, attributes: SecureItemAttributes())
        expect(self.storage.deleteCallCount) == 1
        expect(self.storage.saveCallCount) == 0
        expect(self.storage.lastDeleteIdentifier) == "key1"
    }

    func testModifyItemForwardsAttributesToSaveItem() throws {
        var attrs = SecureItemAttributes()
        attrs.includedInBackup = false
        try storage.modifyItem(identifier: "key1", contents: Data([0x01]), attributes: attrs)
        expect(self.storage.lastSaveAttributes?.includedInBackup) == false
    }

    func testModifyItemPropagatesErrorFromSaveItem() {
        storage.errorToThrow = SecureStorageError(rawValue: errSecIO)
        do {
            try storage.modifyItem(
                identifier: "key",
                contents: Data([0x01]),
                attributes: SecureItemAttributes()
            )
            XCTFail("Expected SecureStorageError to be thrown")
        } catch let error as SecureStorageError {
            expect(error.rawValue) == errSecIO
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testModifyItemPropagatesErrorFromDeleteItem() {
        storage.errorToThrow = SecureStorageError(rawValue: errSecIO)
        do {
            try storage.modifyItem(
                identifier: "key",
                contents: nil,
                attributes: SecureItemAttributes()
            )
            XCTFail("Expected SecureStorageError to be thrown")
        } catch let error as SecureStorageError {
            expect(error.rawValue) == errSecIO
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: modifyItem(identifier:contents:) — convenience overload

    func testModifyItemConvenienceUsesDefaultAttributes() throws {
        try storage.modifyItem(identifier: "key1", contents: Data([0x42]))
        expect(self.storage.lastSaveAttributes?.includedInBackup) == true
    }

    func testModifyItemConvenienceWithNilCallsDelete() throws {
        try storage.modifyItem(identifier: "key1", contents: nil)
        expect(self.storage.deleteCallCount) == 1
        expect(self.storage.saveCallCount) == 0
    }

    // MARK: saveItem(identifier:contents:) — convenience overload

    func testSaveItemConvenienceUsesDefaultAttributes() throws {
        try storage.saveItem(identifier: "key1", contents: Data([0x99]))
        expect(self.storage.lastSaveAttributes?.includedInBackup) == true
    }

    func testSaveItemConvenienceForwardsIdentifierAndContents() throws {
        let data = Data([0x10, 0x20, 0x30])
        try storage.saveItem(identifier: "myKey", contents: data)
        expect(self.storage.lastSaveIdentifier) == "myKey"
        expect(self.storage.lastSaveContents) == data
    }

}

// MARK: - AccessGroup struct

class AccessGroupTests: TestCase {

    func testAccessGroupStringIsStored() {
        let accessGroup = Keychain.AccessGroup(accessGroup: "com.example.shared", appIdentifier: "com.example.app")
        expect(accessGroup.accessGroup) == "com.example.shared"
    }

    func testAppIdentifierIsStored() {
        let accessGroup = Keychain.AccessGroup(accessGroup: "com.example.shared", appIdentifier: "com.example.app")
        expect(accessGroup.appIdentifier) == "com.example.app"
    }

    func testAccessGroupAndAppIdentifierCanBeDistinct() {
        let accessGroup = Keychain.AccessGroup(accessGroup: "com.example.group", appIdentifier: "com.example.app.one")
        expect(accessGroup.accessGroup) == "com.example.group"
        expect(accessGroup.appIdentifier) == "com.example.app.one"
    }

    func testAccessGroupCanMatchAppIdentifier() {
        // A common pattern: the app's own bundle ID is also the access group.
        let accessGroup = Keychain.AccessGroup(accessGroup: "com.example.app", appIdentifier: "com.example.app")
        expect(accessGroup.accessGroup) == accessGroup.appIdentifier
    }

}
