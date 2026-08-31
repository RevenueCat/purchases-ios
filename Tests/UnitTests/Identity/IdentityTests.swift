//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentityTests.swift
//
//  Created by RevenueCat on 8/18/26.

import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class IdentityTests: TestCase {

    // MARK: - Identity

    func testAnonymousIdentityHasAnonymousSource() {
        let identity: Identity = .anonymous

        expect(identity.identitySource) === IdentitySource.anonymous
    }

    func testSignInWithAppleFactoryCreatesIdentityWithSignInWithAppleSource() {
        let token = "identity-token".asData
        let identity = Identity.signInWithApple(token)

        expect(identity.identitySource) === IdentitySource.signInWithApple
    }

    func testSignInWithAppleFactoryCreatesDistinctIdentitiesForDifferentTokens() {
        let identity1 = Identity.signInWithApple("token-1".asData)
        let identity2 = Identity.signInWithApple("token-2".asData)

        expect(identity1.authToken.cacheIdentifier) != identity2.authToken.cacheIdentifier
    }

    func testSignInWithAppleFactoryCreatesEqualCacheIdentifierForSameToken() {
        let token = "identity-token".asData
        let identity1 = Identity.signInWithApple(token)
        let identity2 = Identity.signInWithApple(token)

        expect(identity1.authToken.cacheIdentifier) == identity2.authToken.cacheIdentifier
    }

    func testOIDCFactoryCreatesIdentityWithOIDCSource() {
        let token = "identity-token".asData
        let identity = Identity.oidc(token)

        expect(identity.identitySource) === IdentitySource.oidc
    }

    func testOIDCFactoryCreatesDistinctIdentitiesForDifferentTokens() {
        let identity1 = Identity.oidc("token-1".asData)
        let identity2 = Identity.oidc("token-2".asData)

        expect(identity1.authToken.cacheIdentifier) != identity2.authToken.cacheIdentifier
    }

    func testOIDCFactoryCreatesEqualCacheIdentifierForSameToken() {
        let token = "identity-token".asData
        let identity1 = Identity.oidc(token)
        let identity2 = Identity.oidc(token)

        expect(identity1.authToken.cacheIdentifier) == identity2.authToken.cacheIdentifier
    }

    func testFirebaseFactoryCreatesIdentityWithFirebaseSource() {
        let token = "identity-token".asData
        let identity = Identity.firebase(token)

        expect(identity.identitySource) === IdentitySource.firebase
    }

    func testFirebaseFactoryCreatesDistinctIdentitiesForDifferentTokens() {
        let identity1 = Identity.firebase("token-1".asData)
        let identity2 = Identity.firebase("token-2".asData)

        expect(identity1.authToken.cacheIdentifier) != identity2.authToken.cacheIdentifier
    }

    func testFirebaseFactoryCreatesEqualCacheIdentifierForSameToken() {
        let token = "identity-token".asData
        let identity1 = Identity.firebase(token)
        let identity2 = Identity.firebase(token)

        expect(identity1.authToken.cacheIdentifier) == identity2.authToken.cacheIdentifier
    }

    // MARK: - IdentitySource

    func testIdentitySourceAllCasesContainsEverySource() {
        let rawValues = Set(IdentitySource.allCases.map { $0.rawValue })

        expect(rawValues) == Set(["anonymous", "oidc", "google", "apple", "facebook", "firebase"])
    }

    func testIdentitySourceDescriptionMatchesRawValue() {
        for source in IdentitySource.allCases {
            expect(source.description) == source.rawValue
        }
    }

    func testIdentitySourceWithRawValueReturnsMatchingCase() {
        for source in IdentitySource.allCases {
            expect(IdentitySource.source(with: source.rawValue)) === source
        }
    }

    func testIdentitySourceWithUnrecognizedRawValueReturnsNil() {
        expect(IdentitySource.source(with: "not-a-real-source")).to(beNil())
    }

    // MARK: - IdentityAuthToken

    func testAuthenticationMethodMapsToExpectedSource() {
        let data = "token".asData

        expect(IdentityAuthToken.anonymous.authenticationMethod) === IdentitySource.anonymous
        expect(IdentityAuthToken.oidc(data).authenticationMethod) === IdentitySource.oidc
        expect(IdentityAuthToken.google(data).authenticationMethod) === IdentitySource.google
        expect(IdentityAuthToken.signInWithApple(data).authenticationMethod) === IdentitySource.signInWithApple
        expect(IdentityAuthToken.facebook(data, nil).authenticationMethod) === IdentitySource.facebook
        expect(IdentityAuthToken.facebook(data, "user@example.com").authenticationMethod) === IdentitySource.facebook
        expect(IdentityAuthToken.firebase(data).authenticationMethod) === IdentitySource.firebase
    }

    func testCacheIdentifierForAnonymousIsConstant() {
        expect(IdentityAuthToken.anonymous.cacheIdentifier) == "anon"
    }

    func testCacheIdentifierUsesExpectedPrefixPerCase() {
        let data = "some-token-data".asData

        expect(IdentityAuthToken.oidc(data).cacheIdentifier).to(beginWith("oidc-"))
        expect(IdentityAuthToken.google(data).cacheIdentifier).to(beginWith("google-"))
        expect(IdentityAuthToken.signInWithApple(data).cacheIdentifier).to(beginWith("siwa-"))
        expect(IdentityAuthToken.facebook(data, nil).cacheIdentifier).to(beginWith("fb-"))
        expect(IdentityAuthToken.firebase(data).cacheIdentifier).to(beginWith("firebase-"))
    }

    func testCacheIdentifierIsDeterministicForIdenticalData() {
        let data = "consistent-token".asData

        expect(IdentityAuthToken.oidc(data).cacheIdentifier) == IdentityAuthToken.oidc(data).cacheIdentifier
        expect(IdentityAuthToken.signInWithApple(data).cacheIdentifier)
            == IdentityAuthToken.signInWithApple(data).cacheIdentifier
    }

    func testCacheIdentifierDiffersForDifferentData() {
        let data1 = "token-1".asData
        let data2 = "token-2".asData

        expect(IdentityAuthToken.oidc(data1).cacheIdentifier) != IdentityAuthToken.oidc(data2).cacheIdentifier
    }

    func testCacheIdentifierForFacebookIgnoresEmail() {
        let data = "fb-token".asData

        // The email is not part of the cache identifier, only the token data is.
        expect(IdentityAuthToken.facebook(data, nil).cacheIdentifier)
            == IdentityAuthToken.facebook(data, "user@example.com").cacheIdentifier
    }

    func testValidateIsAlwaysTrueForAnonymous() {
        expect(IdentityAuthToken.anonymous.validate()) == true
    }

    func testValidateIsFalseForEmptyTokenData() {
        let empty = Data()

        expect(IdentityAuthToken.oidc(empty).validate()) == false
        expect(IdentityAuthToken.google(empty).validate()) == false
        expect(IdentityAuthToken.signInWithApple(empty).validate()) == false
        expect(IdentityAuthToken.facebook(empty, nil).validate()) == false
        expect(IdentityAuthToken.firebase(empty).validate()) == false
    }

    func testValidateIsTrueForNonEmptyTokenData() {
        let data = "non-empty".asData

        expect(IdentityAuthToken.oidc(data).validate()) == true
        expect(IdentityAuthToken.google(data).validate()) == true
        expect(IdentityAuthToken.signInWithApple(data).validate()) == true
        expect(IdentityAuthToken.facebook(data, nil).validate()) == true
        expect(IdentityAuthToken.firebase(data).validate()) == true
    }

}
