//
//  AuthenticationAPI.swift
//  ObjcAPITester
//
//  Created by Dave DeLong on 8/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
@_spi(Internal) import RevenueCat

func checkAuthenticationAPI() {

    let p = Purchases.configure(withAPIKey: "")

    let auth = p.authentication
    auth.delegate = nil

    auth.identifyCurrentUser(as: "") { (info: CustomerInfo?, created: Bool, error: PublicError?) in

    }

    auth.logOut { (info: CustomerInfo?, error: PublicError?) in

    }

    let _: String? = auth.currentAccessToken

    let siwa: Identity = Identity.signInWithApple(Data())
    let _: IdentitySource = siwa.identitySource

    let _: IdentitySource = IdentitySource.anonymous
    let _: IdentitySource = IdentitySource.signInWithApple
    let _: IdentitySource = IdentitySource.google
    let _: IdentitySource = IdentitySource.firebase
    let _: IdentitySource = IdentitySource.facebook
    let _: IdentitySource = IdentitySource.oidc

    Task {
        let result = try await auth.identifyCurrentUser(as: "")
        let _: CustomerInfo = result.customerInfo
        let _: Bool = result.created
        let _: CustomerInfo = try await auth.logOut()
    }
}

class AuthDelegate: NSObject, AuthenticationDelegate {
    func authenticatorDidEncounterError(_ error: PublicError) { }
    func authenticatorDidUpdateAccessToken(_ newAccessToken: String?) { }
}
