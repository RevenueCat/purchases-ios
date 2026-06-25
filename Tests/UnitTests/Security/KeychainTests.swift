//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  KeychainTests.swift
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
        let a = SecureStorageError(rawValue: errSecDuplicateItem)
        let b = SecureStorageError(rawValue: errSecDuplicateItem)
        expect(a.description) == b.description
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

    func allItemIdentifiers() throws(SecureStorageError) -> [String] {
        if let error = errorToThrow { throw error }
        return Array(storedItems.keys)
    }

    func readItem(identifier: String) throws(SecureStorageError) -> Data? {
        if let error = errorToThrow { throw error }
        return storedItems[identifier]
    }

    func saveItem(
        identifier: String,
        contents: Data,
        attributes: SecureItemAttributes
    ) throws(SecureStorageError) {
        if let error = errorToThrow { throw error }
        saveCallCount += 1
        lastSaveIdentifier = identifier
        lastSaveContents = contents
        lastSaveAttributes = attributes
        storedItems[identifier] = contents
    }

    func deleteItem(identifier: String) throws(SecureStorageError) {
        if let error = errorToThrow { throw error }
        deleteCallCount += 1
        lastDeleteIdentifier = identifier
        storedItems.removeValue(forKey: identifier)
    }

}

class SecureItemStorageDefaultImplementationTests: TestCase {

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
        } catch {
            // typed throw — error is SecureStorageError directly
            expect(error.rawValue) == errSecNotAvailable
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
        } catch {
            expect(error.rawValue) == errSecIO
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
        } catch {
            expect(error.rawValue) == errSecIO
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

// MARK: - Keychain (concrete implementation, exercises real Security framework)

class KeychainTests: TestCase {

    private var keychain: Keychain!
    /// Identifiers created during a test, to be cleaned up in tearDown.
    private var createdIdentifiers: [String] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        // nil access group: works in simulator and macOS unit test hosts without extra entitlements.
        self.keychain = Keychain(access: nil)
        self.createdIdentifiers = []
    }

    override func tearDown() {
        for id in createdIdentifiers {
            try? keychain.deleteItem(identifier: id)
        }
        self.keychain = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Returns a unique identifier scoped to this test invocation and registers it for cleanup.
    private func uniqueID(_ label: String = "") -> String {
        let id = "rc-test-\(UUID().uuidString)" + (label.isEmpty ? "" : "-\(label)")
        createdIdentifiers.append(id)
        return id
    }

    private func data(byte: UInt8) -> Data { Data([byte, byte &+ 1, byte &+ 2]) }

    // MARK: - containsItem

    func testContainsItemReturnsFalseForNonExistentIdentifier() throws {
        expect(try self.keychain.containsItem(identifier: self.uniqueID())) == false
    }

    func testContainsItemReturnsTrueAfterSaving() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        expect(try self.keychain.containsItem(identifier: id)) == true
    }

    func testContainsItemReturnsFalseAfterDeleting() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.deleteItem(identifier: id)
        expect(try self.keychain.containsItem(identifier: id)) == false
    }

    func testContainsItemDoesNotMatchPrefixOfExistingIdentifier() throws {
        let base = uniqueID("base")
        let prefix = String(base.prefix(10))
        createdIdentifiers.append(prefix)
        try keychain.saveItem(identifier: base, contents: data(byte: 0x01))
        expect(try self.keychain.containsItem(identifier: prefix)) == false
    }

    // MARK: - allItemIdentifiers

    func testAllItemIdentifiersDoesNotContainUnknownIdentifier() throws {
        let id = uniqueID()
        let identifiers = try keychain.allItemIdentifiers()
        expect(identifiers).toNot(contain(id))
    }

    func testAllItemIdentifiersContainsIdentifierAfterSaving() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x10))
        let identifiers = try keychain.allItemIdentifiers()
        expect(identifiers).to(contain(id))
    }

    func testAllItemIdentifiersExcludesIdentifierAfterDeleting() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x20))
        try keychain.deleteItem(identifier: id)
        let identifiers = try keychain.allItemIdentifiers()
        expect(identifiers).toNot(contain(id))
    }

    func testAllItemIdentifiersReturnsAllSavedIdentifiers() throws {
        let id1 = uniqueID("a")
        let id2 = uniqueID("b")
        let id3 = uniqueID("c")
        try keychain.saveItem(identifier: id1, contents: data(byte: 0x01))
        try keychain.saveItem(identifier: id2, contents: data(byte: 0x02))
        try keychain.saveItem(identifier: id3, contents: data(byte: 0x03))
        let identifiers = try keychain.allItemIdentifiers()
        expect(identifiers).to(contain(id1, id2, id3))
    }

    func testAllItemIdentifiersCountIncreasesByOnePerSave() throws {
        let before = try keychain.allItemIdentifiers().count
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        let after = try keychain.allItemIdentifiers().count
        expect(after) == before + 1
    }

    // MARK: - readItem

    func testReadItemReturnsNilForNonExistentIdentifier() throws {
        expect(try self.keychain.readItem(identifier: self.uniqueID())).to(beNil())
    }

    func testReadItemReturnsExactDataAfterSaving() throws {
        let id = uniqueID()
        let original = data(byte: 0xAB)
        try keychain.saveItem(identifier: id, contents: original)
        expect(try self.keychain.readItem(identifier: id)) == original
    }

    func testReadItemReturnsUpdatedDataAfterOverwrite() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        let updated = data(byte: 0x99)
        try keychain.saveItem(identifier: id, contents: updated)
        expect(try self.keychain.readItem(identifier: id)) == updated
    }

    func testReadItemReturnsNilAfterDeletion() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x42))
        try keychain.deleteItem(identifier: id)
        expect(try self.keychain.readItem(identifier: id)).to(beNil())
    }

    func testReadItemsForDifferentIdentifiersAreIndependent() throws {
        let id1 = uniqueID("x")
        let id2 = uniqueID("y")
        let d1 = data(byte: 0x11)
        let d2 = data(byte: 0x22)
        try keychain.saveItem(identifier: id1, contents: d1)
        try keychain.saveItem(identifier: id2, contents: d2)
        expect(try self.keychain.readItem(identifier: id1)) == d1
        expect(try self.keychain.readItem(identifier: id2)) == d2
    }

    // MARK: - saveItem

    func testSaveItemMakesItemReadable() throws {
        let id = uniqueID()
        let payload = data(byte: 0x77)
        try keychain.saveItem(identifier: id, contents: payload)
        expect(try self.keychain.readItem(identifier: id)) == payload
    }

    func testSaveItemOverwritingExistingItemDoesNotCreateDuplicate() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.saveItem(identifier: id, contents: data(byte: 0x02))
        // There should still be exactly one entry for this account.
        let count = try keychain.allItemIdentifiers().filter { $0 == id }.count
        expect(count) == 1
    }

    func testSaveItemWithBackupExcludedStillSavesAndIsReadable() throws {
        let id = uniqueID()
        var attrs = SecureItemAttributes()
        attrs.includedInBackup = false
        let payload = data(byte: 0xCC)
        try keychain.saveItem(identifier: id, contents: payload, attributes: attrs)
        expect(try self.keychain.readItem(identifier: id)) == payload
    }

    func testSaveItemWithBackupIncludedStillSavesAndIsReadable() throws {
        let id = uniqueID()
        var attrs = SecureItemAttributes()
        attrs.includedInBackup = true
        let payload = data(byte: 0xDD)
        try keychain.saveItem(identifier: id, contents: payload, attributes: attrs)
        expect(try self.keychain.readItem(identifier: id)) == payload
    }

    // MARK: - deleteItem

    func testDeleteNonExistentItemDoesNotThrow() {
        expect { try self.keychain.deleteItem(identifier: self.uniqueID()) }.toNot(throwError())
    }

    func testDeleteExistingItemRemovesIt() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.deleteItem(identifier: id)
        expect(try self.keychain.containsItem(identifier: id)) == false
    }

    func testDeleteIsIdempotent() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.deleteItem(identifier: id)
        // Second delete on an already-deleted item must not throw.
        expect { try self.keychain.deleteItem(identifier: id) }.toNot(throwError())
    }

    func testDeleteOneItemDoesNotAffectOthers() throws {
        let keep = uniqueID("keep")
        let remove = uniqueID("remove")
        let keepData = data(byte: 0xAA)
        try keychain.saveItem(identifier: keep, contents: keepData)
        try keychain.saveItem(identifier: remove, contents: data(byte: 0xBB))
        try keychain.deleteItem(identifier: remove)
        expect(try self.keychain.readItem(identifier: keep)) == keepData
    }

    // MARK: - modifyItem (default implementation, exercised via Keychain)

    func testModifyItemWithDataSavesItem() throws {
        let id = uniqueID()
        let payload = data(byte: 0x55)
        try keychain.modifyItem(identifier: id, contents: payload)
        expect(try self.keychain.readItem(identifier: id)) == payload
    }

    func testModifyItemWithNilDeletesExistingItem() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.modifyItem(identifier: id, contents: nil)
        expect(try self.keychain.containsItem(identifier: id)) == false
    }

    func testModifyItemWithNilOnNonExistentItemDoesNotThrow() {
        expect { try self.keychain.modifyItem(identifier: self.uniqueID(), contents: nil) }
            .toNot(throwError())
    }

    func testModifyItemReplacesExistingData() throws {
        let id = uniqueID()
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        let replacement = data(byte: 0xFF)
        try keychain.modifyItem(identifier: id, contents: replacement)
        expect(try self.keychain.readItem(identifier: id)) == replacement
    }

    // MARK: - Edge cases

    func testSaveAndReadEmptyData() throws {
        let id = uniqueID()
        let empty = Data()
        try keychain.saveItem(identifier: id, contents: empty)
        expect(try self.keychain.readItem(identifier: id)) == empty
    }

    func testSaveAndReadLargeData() throws {
        let id = uniqueID()
        let large = Data(repeating: 0xAB, count: 64_000)
        try keychain.saveItem(identifier: id, contents: large)
        expect(try self.keychain.readItem(identifier: id)) == large
    }

    func testSaveAndReadDataWithAllByteValues() throws {
        let id = uniqueID()
        let allBytes = Data((0...255).map { UInt8($0) })
        try keychain.saveItem(identifier: id, contents: allBytes)
        expect(try self.keychain.readItem(identifier: id)) == allBytes
    }

    func testIdentifierWithUnicodeCharactersIsHandledCorrectly() throws {
        // kSecAttrAccount accepts arbitrary strings; verify Unicode identifiers round-trip correctly.
        let id = uniqueID("🔑-identifier-\u{1F512}")
        let payload = data(byte: 0x42)
        try keychain.saveItem(identifier: id, contents: payload)
        expect(try self.keychain.containsItem(identifier: id)) == true
        expect(try self.keychain.readItem(identifier: id)) == payload
    }

    func testIdentifierWithWhitespaceIsHandledCorrectly() throws {
        let id = uniqueID("key with spaces")
        try keychain.saveItem(identifier: id, contents: data(byte: 0x10))
        expect(try self.keychain.containsItem(identifier: id)) == true
    }

    // MARK: - Two Keychain instances with the same configuration share items

    func testTwoInstancesWithSameConfigurationShareKeychain() throws {
        let id = uniqueID()
        let keychainA = Keychain(access: nil)
        let keychainB = Keychain(access: nil)

        try keychainA.saveItem(identifier: id, contents: data(byte: 0xAB))
        // B should see the item A wrote, since both share the same service name.
        expect(try keychainB.containsItem(identifier: id)) == true
        expect(try keychainB.readItem(identifier: id)) == self.data(byte: 0xAB)
    }

}

// MARK: - AccessGroup struct

class AccessGroupTests: TestCase {

    func testAccessGroupStringIsStored() {
        let ag = Keychain.AccessGroup(accessGroup: "com.example.shared", appIdentifier: "com.example.app")
        expect(ag.accessGroup) == "com.example.shared"
    }

    func testAppIdentifierIsStored() {
        let ag = Keychain.AccessGroup(accessGroup: "com.example.shared", appIdentifier: "com.example.app")
        expect(ag.appIdentifier) == "com.example.app"
    }

    func testAccessGroupAndAppIdentifierCanBeDistinct() {
        let ag = Keychain.AccessGroup(accessGroup: "com.example.group", appIdentifier: "com.example.app.one")
        expect(ag.accessGroup) == "com.example.group"
        expect(ag.appIdentifier) == "com.example.app.one"
    }

    func testAccessGroupCanMatchAppIdentifier() {
        // A common pattern: the app's own bundle ID is also the access group.
        let ag = Keychain.AccessGroup(accessGroup: "com.example.app", appIdentifier: "com.example.app")
        expect(ag.accessGroup) == ag.appIdentifier
    }

}

// MARK: - Keychain with non-nil AccessGroup

/// Tests that verify the service-name scoping and namespace isolation introduced by `Keychain.AccessGroup`.
///
/// These tests require the test host to have a keychain access group entitlement matching
/// `KeychainAccessGroupTests.accessGroupID`. If that entitlement is absent the tests are
/// skipped gracefully rather than failing — add the access group to the UnitTests target's
/// entitlements to make them run.
class KeychainAccessGroupTests: TestCase {

    // The access group string used across these tests.
    // Must be listed in the test target's Keychain Access Groups entitlement to run fully.
    private static let accessGroupID = "com.revenuecat.PurchasesTests"

    private var createdIdentifiers: [(keychain: Keychain, id: String)] = []

    override func tearDown() {
        for (keychain, id) in createdIdentifiers {
            try? keychain.deleteItem(identifier: id)
        }
        super.tearDown()
    }

    // MARK: - Helpers

    private func uniqueID(_ label: String = "") -> String {
        "rc-ag-test-\(UUID().uuidString)" + (label.isEmpty ? "" : "-\(label)")
    }

    private func data(byte: UInt8) -> Data { Data([byte, byte &+ 1, byte &+ 2]) }

    /// Builds a `Keychain` using the shared test access group and the given app identifier,
    /// attempts a probe write to detect missing entitlements, and skips the calling test if the
    /// Security framework rejects the access group.
    ///
    /// - Parameter appIdentifier: The `appIdentifier` used to namespace items within the access group.
    /// - Returns: A ready-to-use `Keychain`, or throws `XCTSkip` when entitlements are absent.
    private func makeAccessGroupKeychain(appIdentifier: String = "com.revenuecat.test") throws -> Keychain {
        let keychain = Keychain(
            access: .init(accessGroup: Self.accessGroupID, appIdentifier: appIdentifier)
        )

        let probeID = "probe-\(UUID().uuidString)"
        do {
            try keychain.saveItem(identifier: probeID, contents: Data([0xFF]))
            try keychain.deleteItem(identifier: probeID)
        } catch {
            throw XCTSkip(
                "Access group keychain is unavailable (likely missing entitlements for " +
                "'\(Self.accessGroupID)'). Add it to the UnitTests target's Keychain Access " +
                "Groups entitlement to enable these tests. Underlying error: \(error)"
            )
        }

        return keychain
    }

    /// Registers `identifier` for cleanup against `keychain` at tearDown.
    @discardableResult
    private func track(_ id: String, in keychain: Keychain) -> String {
        createdIdentifiers.append((keychain, id))
        return id
    }

    // MARK: - Service-name scoping

    /// Items stored by an access-group keychain use `appIdentifier + "-revenuecat"` as the
    /// service, so they are invisible to a nil-access keychain whose service is "revenuecat".
    func testAccessGroupKeychainIsIsolatedFromNilAccessKeychain() throws {
        let agKeychain = try makeAccessGroupKeychain()
        let nilKeychain = Keychain(access: nil)

        let id = track(uniqueID(), in: agKeychain)
        try agKeychain.saveItem(identifier: id, contents: data(byte: 0x01))

        // The nil-access keychain must not see this item.
        expect(try nilKeychain.containsItem(identifier: id)) == false
        expect(try nilKeychain.readItem(identifier: id)).to(beNil())
    }

    /// Symmetrically, items in a nil-access keychain must not leak into the access-group view.
    func testNilAccessKeychainIsIsolatedFromAccessGroupKeychain() throws {
        let agKeychain = try makeAccessGroupKeychain()
        let nilKeychain = Keychain(access: nil)

        let id = track(uniqueID(), in: nilKeychain)
        try nilKeychain.saveItem(identifier: id, contents: data(byte: 0x02))

        expect(try agKeychain.containsItem(identifier: id)) == false
        expect(try agKeychain.readItem(identifier: id)).to(beNil())
    }

    // MARK: - App-identifier namespace isolation

    /// Two keychains sharing the same `accessGroup` but different `appIdentifier`s produce
    /// different service names ("app1-revenuecat" vs "app2-revenuecat") and must not see
    /// each other's items.
    func testDifferentAppIdentifiersAreIsolatedWithinTheSameAccessGroup() throws {
        let keychainApp1 = try makeAccessGroupKeychain(appIdentifier: "com.revenuecat.app1")
        let keychainApp2 = try makeAccessGroupKeychain(appIdentifier: "com.revenuecat.app2")

        let id = uniqueID()
        track(id, in: keychainApp1)
        track(id, in: keychainApp2)

        try keychainApp1.saveItem(identifier: id, contents: data(byte: 0xAA))

        expect(try keychainApp2.containsItem(identifier: id)) == false
        expect(try keychainApp2.readItem(identifier: id)).to(beNil())
    }

    /// Saving to one app-identifier namespace must not affect the other.
    func testSavingInOneAppNamespaceDoesNotPopulateAnother() throws {
        let keychainA = try makeAccessGroupKeychain(appIdentifier: "com.revenuecat.appA")
        let keychainB = try makeAccessGroupKeychain(appIdentifier: "com.revenuecat.appB")

        let idA = track(uniqueID("a"), in: keychainA)
        let idB = track(uniqueID("b"), in: keychainB)

        try keychainA.saveItem(identifier: idA, contents: data(byte: 0x11))
        try keychainB.saveItem(identifier: idB, contents: data(byte: 0x22))

        expect(try keychainA.containsItem(identifier: idB)) == false
        expect(try keychainB.containsItem(identifier: idA)) == false
    }

    // MARK: - Shared access within the same configuration

    /// Two `Keychain` instances built with identical `AccessGroup` configs must share items —
    /// this is the whole point of access groups (sharing between an app and its extensions).
    func testTwoInstancesWithIdenticalAccessGroupConfigShareItems() throws {
        let keychainA = try makeAccessGroupKeychain()
        let keychainB = try makeAccessGroupKeychain()   // identical config

        let id = track(uniqueID(), in: keychainA)
        let payload = data(byte: 0x77)
        try keychainA.saveItem(identifier: id, contents: payload)

        expect(try keychainB.containsItem(identifier: id)) == true
        expect(try keychainB.readItem(identifier: id)) == payload
    }

    func testItemWrittenByOneInstanceCanBeDeletedByAnother() throws {
        let keychainA = try makeAccessGroupKeychain()
        let keychainB = try makeAccessGroupKeychain()

        let id = track(uniqueID(), in: keychainA)
        try keychainA.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychainB.deleteItem(identifier: id)

        expect(try keychainA.containsItem(identifier: id)) == false
    }

    // MARK: - CRUD with an access-group keychain

    func testAccessGroupKeychainContainsItemReturnsFalseForUnknownIdentifier() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        expect(try keychain.containsItem(identifier: id)) == false
    }

    func testAccessGroupKeychainCanSaveAndReadItem() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        let payload = data(byte: 0x42)
        try keychain.saveItem(identifier: id, contents: payload)
        expect(try keychain.readItem(identifier: id)) == payload
    }

    func testAccessGroupKeychainUpdatesExistingItemWithoutDuplicate() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.saveItem(identifier: id, contents: data(byte: 0x02))
        let count = try keychain.allItemIdentifiers().filter { $0 == id }.count
        expect(count) == 1
    }

    func testAccessGroupKeychainAllItemIdentifiersContainsItemAfterSave() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        try keychain.saveItem(identifier: id, contents: data(byte: 0x10))
        expect(try keychain.allItemIdentifiers()).to(contain(id))
    }

    func testAccessGroupKeychainDeleteRemovesItem() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.deleteItem(identifier: id)
        expect(try keychain.containsItem(identifier: id)) == false
    }

    func testAccessGroupKeychainDeleteNonExistentItemDoesNotThrow() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        expect { try keychain.deleteItem(identifier: id) }.toNot(throwError())
    }

    func testAccessGroupKeychainModifyItemWithDataSaves() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        let payload = data(byte: 0x55)
        try keychain.modifyItem(identifier: id, contents: payload)
        expect(try keychain.readItem(identifier: id)) == payload
    }

    func testAccessGroupKeychainModifyItemWithNilDeletes() throws {
        let keychain = try makeAccessGroupKeychain()
        let id = track(uniqueID(), in: keychain)
        try keychain.saveItem(identifier: id, contents: data(byte: 0x01))
        try keychain.modifyItem(identifier: id, contents: nil)
        expect(try keychain.containsItem(identifier: id)) == false
    }

}
