//
//  TokenManager.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

class TokenManager {

    fileprivate enum Key {
        case refresh(String)
        case access(String)
        case id(String)

        var identifier: String {
            switch self {
            case .refresh(let user): return "RC-refresh-\(user)"
            case .access(let user): return "RC-access-\(user)"
            case .id(let user): return "RC-id-\(user)"
            }
        }
    }

    let enabled: Bool
    private let storage: any SecureItemStorage

    weak var currentUserProvider: CurrentUserProvider?

    private var currentUser: String? { currentUserProvider?.currentAppUserID }

    init(enabled: Bool, storage: any SecureItemStorage) {
        self.enabled = enabled
        self.storage = storage
    }

    var reportError: ((PublicError) -> Void)?

    var hasCurrentAccessToken: Bool { currentAccessToken != nil }

    var currentIdentitySources: [IdentitySource]? {
        guard let currentIDToken else { return nil }
        guard let jwt = try? JWT(from: currentIDToken) else { return nil }
        return jwt.amr?.compactMap { IdentitySource.source(with: $0) }
    }

    var isCurrentIdentityAnonymous: Bool {
        // returns true iff all (1+) the identity sources are "anonymous"
        guard let sources = currentIdentitySources else { return false }
        if sources.isEmpty { return false }
        return sources.allSatisfy { $0 == .anonymous }
    }

    var currentIdentitySource: IdentitySource? {
        currentIdentitySources?.last
    }

    var currentRefreshToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .refresh(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .refresh(user))
        }
    }

    var currentAccessToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .access(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .access(user))
        }
    }

    var currentIDToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .id(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .id(user))
        }
    }

    func idToken(for user: String) -> String? {
        storage.string(for: .id(user))
    }

    func saveTokens(refreshToken: String?, accessToken: String, idToken: String?, for userID: String) {
        storage.setString(refreshToken, for: .refresh(userID))
        storage.setString(accessToken, for: .access(userID))
        storage.setString(idToken, for: .id(userID))
    }

    func deleteTokens(for userID: String) {
        storage.setString(nil, for: .refresh(userID))
        storage.setString(nil, for: .access(userID))
        storage.setString(nil, for: .id(userID))
    }

    func deleteAccessToken(for userID: String) {
        storage.setString(nil, for: .access(userID))
    }

}

extension SecureItemStorage {

    fileprivate func string(for key: TokenManager.Key) -> String? {
        guard let data = try? self.readItem(identifier: key.identifier) else {
            Logger.debug(Strings.authentication.unknownItem(key.identifier))
            return nil
        }
        return String(bytes: data, encoding: .utf8)
    }

    fileprivate func setString(_ string: String?, for key: TokenManager.Key) {
        let data = string.map { Data($0.utf8) }
        do {
            try self.modifyItem(identifier: key.identifier, contents: data)
        } catch {
            Logger.warn(Strings.authentication.failedModification(key.identifier, error))
        }
    }

}
