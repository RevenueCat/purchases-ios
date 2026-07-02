//
//  Keychain.swift
//  RevenueCat
//
//  Created by Dave DeLong on 6/24/26.
//

import Foundation
import Security

/// A protocol that defines the interface for reading, writing, updating, and deleting secure items
///
/// NOTE: implementations of this protocol should only store items locally on device. Items should
/// not be synchronized to other devices.
protocol SecureItemStorage {

    /// Determine whether the secure storage holds an item with the specified identifier
    ///
    /// This method has a default implementation, derived from ``allItemIdentifiers()``.
    ///
    /// - Parameter identifier: the identifier of the item
    /// - Returns: `true` if the secure storage holds the item; `false` otherwise.
    /// - Throws: a ``SecureStorageError`` if an error occurred during lookup
    func containsItem(identifier: String) throws -> Bool

    /// Return a list of all retrievable identifiers in the secure storage
    ///
    /// - Returns: a list of identifiers
    /// - Throws: a ``SecureStorageError`` if an error occurred during retrieval
    func allItemIdentifiers() throws -> [String]

    /// Read a single secure item
    /// - Parameter identifier: the identifier of the item
    /// - Returns: the item's `Data`, if it exists. Returns `nil` if no item is stored for that identifier.
    /// - Throws: a ``SecureStorageError`` if an error occurred during lookup
    func readItem(identifier: String) throws -> Data?

    /// Save, update, or delete a single secure item.
    ///
    /// This performs a generic "insert, update, or delete" operation of a single secure item. A null `contents`
    /// value results in the item being deleted, if it exists in the secure storage. Otherwise the item is inserted
    /// or updated.
    ///
    /// This method has a default implementation, which is based on ``containsItem(identifier:)``,
    /// ``saveItem(identifier:contents:attributes)``, and
    /// ``deleteItem(identifier:)``.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item
    ///   - contents: The new contents of the item. If this value is `nil`, the item will be deleted
    ///   - attributes: The item's ``SecureItemAttributes``. This value is ignored
    ///   if the contents are `nil`.
    /// - Throws: a ``SecureStorageError`` if an error occurred during modification.
    func modifyItem(identifier: String, contents: Data?, attributes: SecureItemAttributes) throws

    /// Save or update a single secure item
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item
    ///   - contents: The new or updated contents of the secure item
    ///   - attributes: The item's new or updated ``SecureItemAttributes``.
    /// - Throws: a ``SecureStorageError`` if an error occurred during saving.
    func saveItem(identifier: String, contents: Data, attributes: SecureItemAttributes) throws

    /// Delete a single secure item, if it exists.
    ///
    /// If an item with the specified identifier does not exist, this method does nothing.
    ///
    /// - Parameter identifier: The identifier of the item to delete
    /// - Throws: a ``SecureStorageError`` if an error occurred during deletion.
    func deleteItem(identifier: String) throws
}

/// Storage attributes of secure items
struct SecureItemAttributes {

    /// Indicates whether a secure item should be included in the device's backups.
    ///
    /// If this value is `true` (the default), then items will be present in a device's backups
    /// and will be present after a device has been *restored* from that backup.
    ///
    /// If this value is `false`, then items will not be backed up and will not be present
    /// when the device is restored from backup.
    ///
    /// This value does not affect whether items are synced to other devices.
    var includedInBackup: Bool = true

    fileprivate var accessbility: CFString {
        includedInBackup ? kSecAttrAccessibleAfterFirstUnlock : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    }
}

extension SecureItemStorage {

    // default implementation
    func containsItem(identifier: String) throws -> Bool {
        let allIdentifiers = try self.allItemIdentifiers()
        return allIdentifiers.contains(identifier)
    }

    // default implementation
    func modifyItem(identifier: String, contents: Data?, attributes: SecureItemAttributes) throws {
        if let contents {
            try self.saveItem(identifier: identifier, contents: contents, attributes: attributes)
        } else {
            try self.deleteItem(identifier: identifier)
        }
    }

    /// Modify an item, using default ``SecureItemAttributes``.
    ///
    /// - SeeAlso: ``modifyItem(identifier:contents:attributes:)``
    func modifyItem(identifier: String, contents: Data?) throws {
        try self.modifyItem(identifier: identifier, contents: contents, attributes: SecureItemAttributes())
    }

    /// Save an item, using default ``SecureItemAttributes``.
    ///
    /// - SeeAlso: ``saveItem(identifier:contents:attributes:)``
    func saveItem(identifier: String, contents: Data) throws {
        try self.saveItem(identifier: identifier, contents: contents, attributes: SecureItemAttributes())
    }

}

struct Keychain: SecureItemStorage {

    struct AccessGroup {
        // the identifier of the shared keychain, used by the developers apps and/or extensions
        // must be specified in their entitlements as a keychain access group
        let accessGroup: String

        // the identifier of this particular app (and its extensions)
        // this is used to disambiguate values saved by other apps
        // to prevent values from
        let appIdentifier: String
    }

    private let baseQuery: [CFString: Any]

    init(access: AccessGroup?) {
        // start with the base query
        // we store secure blobs as "generic passwords"
        // and default to using the "revenuecat" service
        var base: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "revenuecat"
        ]

        // If we share these blobs with other processes, then set the access group and change the service.
        // Access groups can be shared by multiple *APPS*, not just an app and its extensions. We want to
        // limit shared items to only within the scope of a single app (ie, to just the app and its extensions),
        // so we use the service as an additional namespace.
        //
        // This allows the same developer to use RevenueCat with multiple apps, share their own credentials
        // between them, but the RC SDK will still keep user session tokens scoped to a single app (but shared
        // with its extensions)
        if let access {
            base[kSecAttrAccessGroup] = access.accessGroup
            base[kSecAttrService] = access.appIdentifier + "-revenuecat"
        }

        self.baseQuery = base
    }

    func containsItem(identifier: String) throws -> Bool {
        var query = baseQuery
        query[kSecReturnAttributes] = true
        query[kSecAttrAccount] = identifier
        query[kSecMatchLimit] = kSecMatchLimitAll

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let items = result as? [[CFString: Any]] {
                return items.contains(where: { attributes in
                    (attributes[kSecAttrAccount] as? String) == identifier
                })
            } else {
                throw SecureStorageError(rawValue: errSecInvalidValue)
            }
        case errSecItemNotFound:
            return false
        default:
            throw SecureStorageError(rawValue: status)
        }
    }

    func allItemIdentifiers() throws -> [String] {
        var query = baseQuery
        query[kSecReturnAttributes] = true
        query[kSecMatchLimit] = kSecMatchLimitAll

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let items = result as? [[CFString: Any]] {
                return items.compactMap { attributes -> String? in
                    return attributes[kSecAttrAccount] as? String
                }
            } else {
                throw SecureStorageError(rawValue: errSecInvalidValue)
            }
        case errSecItemNotFound:
            return []
        default:
            throw SecureStorageError(rawValue: status)
        }
    }

    func readItem(identifier: String) throws -> Data? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecAttrAccount] = identifier
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw SecureStorageError(rawValue: errSecInvalidValue)
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw SecureStorageError(rawValue: status)
        }
    }

    func saveItem(identifier: String, contents: Data, attributes: SecureItemAttributes) throws {
        var query = baseQuery
        query[kSecAttrAccount] = identifier

        var addQuery = query
        addQuery[kSecAttrAccessible] = attributes.accessbility
        addQuery[kSecValueData] = contents

        // try to save the item immediately. if we get a "duplicate" error, then update it
        var status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // the item already exists; update it
            let attributes: [CFString: Any] = [
                kSecAttrAccessible: attributes.accessbility,
                kSecValueData: contents
            ]
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }

        if status != errSecSuccess {
            throw SecureStorageError(rawValue: status)
        }
    }

    func deleteItem(identifier: String) throws {
        var query = baseQuery
        query[kSecAttrAccount] = identifier

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStorageError(rawValue: status)
        }
    }

}

struct SecureStorageError: Error, CustomStringConvertible {
    let rawValue: OSStatus
    let description: String

    init(rawValue: OSStatus) {
        self.rawValue = rawValue
        let message = SecCopyErrorMessageString(rawValue, nil)
        self.description = (message as String?) ?? "\(rawValue)"
    }
}
