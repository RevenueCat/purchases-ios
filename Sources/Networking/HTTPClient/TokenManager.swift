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

    init(enabled: Bool, storage: any SecureItemStorage) {
        self.enabled = enabled
        self.storage = storage
    }

    func refreshToken(for userID: String) -> String? {
        guard enabled else { return nil }
        return storage.string(for: .refresh(userID))
    }

    func accessToken(for userID: String) -> String? {
        guard enabled else { return nil }
        return storage.string(for: .access(userID))
    }

    func idToken(for userID: String) -> String? {
        guard enabled else { return nil }
        return storage.string(for: .id(userID))
    }

    func saveTokens(refreshToken: String, accessToken: String, idToken: String?, for userID: String) {
        storage.setString(refreshToken, for: .refresh(userID))
        storage.setString(accessToken, for: .access(userID))
        storage.setString(idToken, for: .id(userID))
    }

    func deleteTokens(for userID: String) {
        storage.setString(nil, for: .refresh(userID))
        storage.setString(nil, for: .access(userID))
        storage.setString(nil, for: .id(userID))
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
