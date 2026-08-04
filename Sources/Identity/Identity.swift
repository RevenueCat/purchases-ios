//
//  Identity.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/8/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

@_spi(Experimental)
@objc(RCIdentity)
public final class Identity: NSObject {

    @objc internal static func anonymous(appUserID: String?) -> Identity {
        Identity(token: .anonymous(appUserID))
    }

//    @objc public static func oidc(_ token: Data) -> Identity {
//        Identity(token: .oidc(token))
//    }
//
//    @objc public static func google(_ token: Data) -> Identity {
//        Identity(token: .google(token))
//    }

    @objc public static func signInWithApple(_ identityToken: Data) -> Identity {
        Identity(token: .signInWithApple(identityToken))
    }

//    @objc public static func facebook(_ idToken: Data) -> Identity {
//        Identity(token: .facebook(idToken, nil))
//    }
//
//    @objc public static func facebook(idToken: Data, email: String) -> Identity {
//        Identity(token: .facebook(idToken, email))
//    }
//
//    @objc public static func firebase(_ token: Data) -> Identity {
//        Identity(token: .firebase(token))
//    }

    internal let authToken: IdentityAuthToken

    private init(token: IdentityAuthToken) {
        self.authToken = token
        super.init()
    }

}

@_spi(Experimental)
@objc(RCIdentitySource)
public enum IdentitySource: Int {
    case anonymous
    case oidc
    case google
    case signInWithApple
    case facebook
    case firebase

    internal init?(amr: String) {
        switch amr {
        case "anonymous": self = .anonymous
        case "oidc": self = .oidc
        case "google": self = .google
        case "apple": self = .signInWithApple
        case "facebook": self = .facebook
        case "firebase": self = .firebase
        default: return nil
        }
    }
}

internal enum IdentityAuthToken: Hashable {
    case anonymous(String?)
    case oidc(Data)
    case google(Data)
    case signInWithApple(Data)
    case facebook(Data, String?)
    case firebase(Data)

    var authenticationMethod: IdentitySource {
        switch self {
        case .anonymous: return .anonymous
        case .oidc: return .oidc
        case .google: return .google
        case .signInWithApple: return .signInWithApple
        case .facebook: return .facebook
        case .firebase: return .firebase
        }
    }

    internal var cacheIdentifier: String {
        switch self {
        case .anonymous(let id): return "anon-\(id ?? "NULL")"
        case .oidc(let data): return "oidc-\(data.hashString)"
        case .google(let data): return "google-\(data.hashString)"
        case .signInWithApple(let data): return "siwa-\(data.hashString)"
        case .facebook(let data, _): return "fb-\(data.hashString)"
        case .firebase(let data): return "firebase-\(data.hashString)"
        }
    }

    internal func validate() -> Bool {
        switch self {
        case .anonymous: return true
        case .oidc(let data): return data.isEmpty == false
        case .google(let data): return data.isEmpty == false
        case .signInWithApple(let data): return data.isEmpty == false
        case .facebook(let data, _): return data.isEmpty == false
        case .firebase(let data): return data.isEmpty == false
        }
    }
}
