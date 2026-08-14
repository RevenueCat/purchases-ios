//
//  AuthenticationAPI.swift
//  ObjcAPITester
//
//  Created by Dave DeLong on 8/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
@_spi(Experimental) import RevenueCat

func checkAuthenticationAPI() {

    let p = Purchases.configure(withAPIKey: "")

    let auth = p.authentication
    auth.delegate = nil

    auth.identifyCurrentUser(as: "") { (info: CustomerInfo?, created: Bool, error: PublicError?) in

    }

    auth.logOut { (info: CustomerInfo?, error: PublicError?) in

    }

    let siwa: Identity = Identity.signInWithApple(Data())
    let source: IdentitySource = siwa.identitySource

    let anonymousSource: IdentitySource = IdentitySource.anonymous
    let appleSource: IdentitySource = IdentitySource.signInWithApple
    let googleSource: IdentitySource = IdentitySource.google
    let firebase: IdentitySource = IdentitySource.firebase
    let facebook: IdentitySource = IdentitySource.facebook
    let oidc: IdentitySource = IdentitySource.oidc

    Task {
        let (customerInfo: CustomerInfo, created: Bool) = try await auth.identifyCurrentUser(as: "")
        let info: CustomerInfo = try await auth.logOut()
    }
}

class AuthDelegate: NSObject, AuthenticationDelegate {
    func authenticatorDidEncounterError(_ error: PublicError) { }
}
