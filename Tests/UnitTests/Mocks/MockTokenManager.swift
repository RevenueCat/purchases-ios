//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTokenManager.swift
//
//  Created by RevenueCat on 8/13/26.

@testable import RevenueCat

class MockTokenManager: TokenManager {

    convenience init(enabled: Bool = false) {
        self.init(enabled: enabled, storage: MockSecureItemStorage())
    }

    // MARK: - currentRefreshToken

    var stubbedCurrentRefreshToken: String?
    private(set) var invokedCurrentRefreshTokenGetter = false
    private(set) var invokedCurrentRefreshTokenGetterCount = 0
    private(set) var invokedCurrentRefreshTokenSetter = false
    private(set) var invokedCurrentRefreshTokenSetterCount = 0
    private(set) var invokedCurrentRefreshTokenSetterParametersList: [String?] = []

    override var currentRefreshToken: String? {
        get {
            self.invokedCurrentRefreshTokenGetter = true
            self.invokedCurrentRefreshTokenGetterCount += 1
            return self.stubbedCurrentRefreshToken
        }
        set {
            self.invokedCurrentRefreshTokenSetter = true
            self.invokedCurrentRefreshTokenSetterCount += 1
            self.invokedCurrentRefreshTokenSetterParametersList.append(newValue)
            self.stubbedCurrentRefreshToken = newValue
        }
    }

    // MARK: - currentAccessToken

    var stubbedCurrentAccessToken: String?
    private(set) var invokedCurrentAccessTokenGetter = false
    private(set) var invokedCurrentAccessTokenGetterCount = 0
    private(set) var invokedCurrentAccessTokenSetter = false
    private(set) var invokedCurrentAccessTokenSetterCount = 0
    private(set) var invokedCurrentAccessTokenSetterParametersList: [String?] = []

    override var currentAccessToken: String? {
        get {
            self.invokedCurrentAccessTokenGetter = true
            self.invokedCurrentAccessTokenGetterCount += 1
            return self.stubbedCurrentAccessToken
        }
        set {
            self.invokedCurrentAccessTokenSetter = true
            self.invokedCurrentAccessTokenSetterCount += 1
            self.invokedCurrentAccessTokenSetterParametersList.append(newValue)
            self.stubbedCurrentAccessToken = newValue
        }
    }

    // Note: `hasCurrentAccessToken` is intentionally not overridden; the base implementation
    // (`currentAccessToken != nil`) dispatches to the override above, so it reflects
    // `stubbedCurrentAccessToken` automatically.

    // MARK: - currentIDToken

    var stubbedCurrentIDToken: String?
    private(set) var invokedCurrentIDTokenGetter = false
    private(set) var invokedCurrentIDTokenGetterCount = 0
    private(set) var invokedCurrentIDTokenSetter = false
    private(set) var invokedCurrentIDTokenSetterCount = 0
    private(set) var invokedCurrentIDTokenSetterParametersList: [String?] = []

    override var currentIDToken: String? {
        get {
            self.invokedCurrentIDTokenGetter = true
            self.invokedCurrentIDTokenGetterCount += 1
            return self.stubbedCurrentIDToken
        }
        set {
            self.invokedCurrentIDTokenSetter = true
            self.invokedCurrentIDTokenSetterCount += 1
            self.invokedCurrentIDTokenSetterParametersList.append(newValue)
            self.stubbedCurrentIDToken = newValue
        }
    }

    // MARK: - idToken(for:)

    var stubbedIDToken: String?
    private(set) var invokedIDTokenFor = false
    private(set) var invokedIDTokenForCount = 0
    private(set) var invokedIDTokenForParametersList: [String] = []

    override func idToken(for user: String) -> String? {
        self.invokedIDTokenFor = true
        self.invokedIDTokenForCount += 1
        self.invokedIDTokenForParametersList.append(user)
        return self.stubbedIDToken
    }

    // MARK: - saveTokens(refreshToken:accessToken:idToken:for:)

    typealias SaveTokensParameters = (refreshToken: String?, accessToken: String, idToken: String?, userID: String)

    private(set) var invokedSaveTokens = false
    private(set) var invokedSaveTokensCount = 0
    private(set) var invokedSaveTokensParametersList: [SaveTokensParameters] = []

    override func saveTokens(refreshToken: String?, accessToken: String, idToken: String?, for userID: String) {
        self.invokedSaveTokens = true
        self.invokedSaveTokensCount += 1
        self.invokedSaveTokensParametersList.append((refreshToken, accessToken, idToken, userID))
    }

    // MARK: - deleteTokens(for:)

    private(set) var invokedDeleteTokens = false
    private(set) var invokedDeleteTokensCount = 0
    private(set) var invokedDeleteTokensParametersList: [String] = []

    override func deleteTokens(for userID: String) {
        self.invokedDeleteTokens = true
        self.invokedDeleteTokensCount += 1
        self.invokedDeleteTokensParametersList.append(userID)
    }

    // MARK: - deleteAccessToken(for:)

    private(set) var invokedDeleteAccessToken = false
    private(set) var invokedDeleteAccessTokenCount = 0
    private(set) var invokedDeleteAccessTokenParametersList: [String] = []

    override func deleteAccessToken(for userID: String) {
        self.invokedDeleteAccessToken = true
        self.invokedDeleteAccessTokenCount += 1
        self.invokedDeleteAccessTokenParametersList.append(userID)
    }

}

extension MockTokenManager: @unchecked Sendable {}
