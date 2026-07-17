//
//  ExternalToken.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/8/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

@_spi(Experimental)
@objc(RCExternalToken)
public final class ExternalToken: NSObject {

    @objc internal static func anonymous(appUserID: String?) -> ExternalToken {
        ExternalToken(token: .anonymous(appUserID))
    }

    @objc public static func oidc(_ token: Data) -> ExternalToken {
        ExternalToken(token: .oidc(token))
    }

    @objc public static func google(_ token: Data) -> ExternalToken {
        ExternalToken(token: .google(token))
    }

    @objc public static func signInWithApple(_ identityToken: Data) -> ExternalToken {
        ExternalToken(token: .siwa(identityToken))
    }

    @objc public static func facebook(_ idToken: Data) -> ExternalToken {
        ExternalToken(token: .facebook(idToken, nil))
    }

    @objc public static func facebook(idToken: Data, email: String) -> ExternalToken {
        ExternalToken(token: .facebook(idToken, email))
    }

    @objc public static func firebase(_ token: Data) -> ExternalToken {
        ExternalToken(token: .firebase(token))
    }

    internal let authToken: ExternalAuthToken

    private init(token: ExternalAuthToken) {
        self.authToken = token
        super.init()
    }

}

internal enum ExternalAuthToken: Hashable {
    case anonymous(String?)
    case oidc(Data)
    case google(Data)
    case siwa(Data)
    case facebook(Data, String?)
    case firebase(Data)

    internal var cacheIdentifier: String {
        switch self {
        case .anonymous(let id): return "anon-\(id ?? "NULL")"
        case .oidc(let data): return "oidc-\(data.hashString)"
        case .google(let data): return "google-\(data.hashString)"
        case .siwa(let data): return "siwa-\(data.hashString)"
        case .facebook(let data, _): return "fb-\(data.hashString)"
        case .firebase(let data): return "firebase-\(data.hashString)"
        }
    }

    internal func validate() -> Bool {
        switch self {
        case .anonymous: return true
        case .oidc(let data): return data.isEmpty == false
        case .google(let data): return data.isEmpty == false
        case .siwa(let data): return data.isEmpty == false
        case .facebook(let data, _): return data.isEmpty == false
        case .firebase(let data): return data.isEmpty == false
        }
    }
}
