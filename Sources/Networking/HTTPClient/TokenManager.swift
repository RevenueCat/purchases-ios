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

    func authorizationHeaders(for urlRequest: URLRequest) -> [String: String] {
        guard enabled else { return [:] }
        guard let currentAccessToken else { return [:] }

        return [
            HTTPClient.RequestHeader.authorization.rawValue: "Bearer \(currentAccessToken)"
        ]

    }

}

extension SecureItemStorage {

    fileprivate func string(for key: TokenManager.Key) -> String? {
        guard let data = try? self.readItem(identifier: key.identifier) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    fileprivate func setString(_ string: String?, for key: TokenManager.Key) {
        let data = string.map { Data($0.utf8) }
        try? self.modifyItem(identifier: key.identifier, contents: data)
    }

}
