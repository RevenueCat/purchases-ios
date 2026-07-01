//
//  KeychainTests.swift
//  RevenueCatTests
//
//  Created by Dave DeLong on 6/30/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
import Security
import XCTest

@testable import RevenueCat

// MARK: - Keychain (concrete implementation, exercises real Security framework)
// The simulator requires a real host app to use the keychain
// Thus, it is part of StoreKitUnitTests
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
        let data1 = data(byte: 0x11)
        let data2 = data(byte: 0x22)
        try keychain.saveItem(identifier: id1, contents: data1)
        try keychain.saveItem(identifier: id2, contents: data2)
        expect(try self.keychain.readItem(identifier: id1)) == data1
        expect(try self.keychain.readItem(identifier: id2)) == data2
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

// MARK: - Keychain with non-nil AccessGroup

/// Tests that verify the service-name scoping and namespace isolation introduced by `Keychain.AccessGroup`.
///
/// These tests require the test host to have a keychain access group entitlement ending in
/// `KeychainAccessGroupTests.accessGroupSuffix`. If that entitlement is absent the tests are
/// skipped gracefully rather than failing — add the access group to the UnitTests target's
/// entitlements to make them run.
class KeychainAccessGroupTests: TestCase {

    // Returns the team identifier prefix (e.g. "A1B2C3D4E5.") by querying
    // the keychain for the access group iOS automatically assigns to items
    // stored without an explicit group.
    private static var accessGroupPrefix: String {
        get throws {
            if _accessGroupPrefix == nil {
                #if os(macOS)
                // On macOS, SecTaskCreateFromSelf() reads entitlements directly from the
                // process's own code signature — no keychain round-trip required.
                // Prefer the explicit team-identifier entitlement; fall back to extracting
                // the team prefix from the first keychain-access-groups entry.
                var macOSPrefix: String?
                if let task = SecTaskCreateFromSelf(nil) {
                    if let teamID = SecTaskCopyValueForEntitlement(
                        task,
                        "com.apple.developer.team-identifier" as CFString,
                        nil
                    ) as? String {
                        macOSPrefix = teamID + "."
                    } else if let groups = SecTaskCopyValueForEntitlement(task,
                                                                          "keychain-access-groups" as CFString,
                                                                          nil) as? [String],
                    let first = groups.first,
                    let teamPart = first.split(separator: ".").first {
                        macOSPrefix = String(teamPart) + "."
                    }
                }
                guard let resolved = macOSPrefix else {
                    XCTFail("Could not determine team identifier prefix from code-signing entitlements")
                    throw NSError(domain: "revenuecat", code: -1)
                }
                _accessGroupPrefix = resolved
                #else
                let account = "rc-team-id-probe-\(UUID().uuidString)"
                let query: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: account,
                    kSecAttrService: "revenuecat-team-id-probe",
                    kSecReturnAttributes: true,
                ]

                var result: AnyObject?
                var status = SecItemCopyMatching(query as CFDictionary, &result)

                if status == errSecItemNotFound {
                    status = SecItemAdd(query as CFDictionary, &result)
                }

                // Clean up the probe item regardless of what happens next
                defer { SecItemDelete(query as CFDictionary) }

                guard status == errSecSuccess,
                      let attrs = result as? [CFString: Any],
                      let accessGroup = attrs[kSecAttrAccessGroup] as? String,
                      let prefix = accessGroup.split(separator: ".").first else {
                    XCTFail("Could not determine team identifier prefix from code-signing entitlements")
                    throw NSError(domain: "revenuecat", code: -1)
                }

                _accessGroupPrefix = String(prefix) + "."
                #endif
            }
            return _accessGroupPrefix!
        }
    }
    private static var _accessGroupPrefix: String?

    // The access group suffix used across these tests.
    // Must be listed in the test target's Keychain Access Groups entitlement to run fully.
    private static let accessGroupSuffix = "com.revenuecat.shared"
    private static var accessGroup: String {
        get throws { try accessGroupPrefix + accessGroupSuffix }
    }

    private static let keychainAccessGroupsEntitlement = "keychain-access-groups"

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

    /// Builds a `Keychain` using the full shared test access group from the host entitlements
    /// and the given app identifier.
    ///
    /// - Parameter appIdentifier: The `appIdentifier` used to namespace items within the access group.
    /// - Returns: A ready-to-use `Keychain`, or throws `XCTSkip` when the entitlement is absent.
    private func makeAccessGroupKeychain(appIdentifier: String = "com.revenuecat.test") throws -> Keychain {
        let keychain = Keychain(
            access: .init(accessGroup: try Self.accessGroup, appIdentifier: appIdentifier)
        )

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
