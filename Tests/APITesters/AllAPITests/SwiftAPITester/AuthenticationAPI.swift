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

    let siwa = Identity.signInWithApple(Data())
    let source = siwa.identitySource

    let anonymousSource = IdentitySource.anonymous
    let appleSource = IdentitySource.signInWithApple
    let googleSource = IdentitySource.google
    let firebase = IdentitySource.firebase
    let facebook = IdentitySource.facebook
    let oidc = IdentitySource.oidc
}

class AuthDelegate: NSObject, AuthenticationDelegate {
    func authenticatorDidEncounterError(_ error: PublicError) { }
}
