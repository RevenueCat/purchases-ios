//
//  Identity.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/8/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// An identity from an external provider
@_spi(Experimental)
@objc(RCIdentity)
public final class Identity: NSObject {

    internal static var anonymous: Identity {
        Identity(token: .anonymous)
    }

//    @objc public static func oidc(_ token: Data) -> Identity {
//        Identity(token: .oidc(token))
//    }
//
//    @objc public static func google(_ token: Data) -> Identity {
//        Identity(token: .google(token))
//    }
    
    /// A Sign In With Apple identity
    /// - Parameter identityToken: The `identityToken` from an `ASAuthorizationAppleIDCredential`
    /// - Returns: An ``Identity`` that can be used to log in to the ``Purchases`` type
    @objc(identityWithSignInWithAppleToken:)
    public static func signInWithApple(_ identityToken: Data) -> Identity {
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
    
    /// Retrieve the source service of this identity
    @objc public var identitySource: IdentitySource { authToken.authenticationMethod }

    private init(token: IdentityAuthToken) {
        self.authToken = token
        super.init()
    }

}

/// The source of an identity
@_spi(Experimental)
@objc(RCIdentitySource)
public final class IdentitySource: NSObject, CaseIterable {
    
    /// An array of all supported identity source values
    public static let allCases: [IdentitySource] = [
        .anonymous, .oidc, .google, .signInWithApple, .facebook, .firebase
    ]
    
    /// The identity is considered "anonymous"
    @objc public static let anonymous = IdentitySource("anonymous")

    /// The identity is from an OpenID Connect provider
    @objc public static let oidc = IdentitySource("oidc")

    /// The identity is from Google
    @objc public static let google = IdentitySource("google")

    /// The identity is a Sign In With Apple identity
    @objc public static let signInWithApple = IdentitySource("signInWithApple")

    /// The identity is from Facebook
    @objc public static let facebook = IdentitySource("facebook")

    /// The identity is from Firebase
    @objc public static let firebase = IdentitySource("firebase")

    internal static func source(with rawValue: String) -> IdentitySource? {
        return allCases.first(where: { $0.rawValue == rawValue })
    }
    
    /// A raw textual representation of this identity, such as `"anonymous"`
    @objc public let rawValue: String

    public override var description: String { rawValue }

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

internal enum IdentityAuthToken: Hashable {
    case anonymous
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
        case .anonymous: return "anon"
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
