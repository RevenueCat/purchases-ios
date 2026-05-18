//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMAPI.swift
//
//  Created by RevenueCat.

import Foundation

/// Handles IAM authentication API calls: `/auth/login` and token refresh.
class IAMAPI {

    typealias LoginResponseHandler = (Result<IAMSession, BackendError>) -> Void

    private let backendConfig: BackendConfiguration
    private let sessionManager: IAMSessionManager
    private let jwtVerifier: IAMJWTVerifier

    init(backendConfig: BackendConfiguration, sessionManager: IAMSessionManager) {
        self.backendConfig = backendConfig
        self.sessionManager = sessionManager
        self.jwtVerifier = IAMJWTVerifier(baseURL: SystemInfo.apiBaseURL)
        // If a session was restored from the Keychain, re-verify its ID token so that
        // idTokenClaims (and the subject inside it) are populated in memory.
        if let idToken = sessionManager.currentSession?.idToken {
            self.verifyAndCacheIDToken(idToken)
        }
    }

    /// Whether an active IAM session exists (i.e. the user has authenticated at least once).
    var hasSession: Bool { return sessionManager.hasSession }

    /// The current session, if one exists.
    var currentSession: IAMSession? { return sessionManager.currentSession }

    /// Clears the current IAM session and any cached ID token claims from memory.
    func clearSession() {
        sessionManager.clearSession()
    }

    /// Whether the current IAM session was established via anonymous login.
    /// Returns `true` when unauthenticated (no session exists).
    var isAnonymous: Bool { return sessionManager.isAnonymous }

    /// The verified claims from the most recent IAM ID token, or `nil` if unavailable.
    var idTokenClaims: IDTokenClaims? { return sessionManager.idTokenClaims }

    /// Authenticates using the given login method and stores the resulting session.
    ///
    /// On success the session is automatically saved in ``IAMSessionManager``.
    /// If the user is already authenticated and the method is non-anonymous, the current
    /// session's ID token is forwarded as `link_to_id` to trigger account linking.
    func login(method: IAMLoginMethod, completion: @escaping LoginResponseHandler) {
        let linkToId: String?
        switch method.methodType {
        case .anonymous:
            linkToId = nil
        default:
            linkToId = sessionManager.currentSession?.idToken
        }

        let operation = IAMLoginOperation(
            configuration: self.backendConfig,
            loginMethod: method,
            linkToId: linkToId
        ) { [weak self] result in
            if case let .success(session) = result {
                self?.sessionManager.saveSession(session)
                if let idToken = session.idToken {
                    self?.verifyAndCacheIDToken(idToken)
                }
            }
            completion(result)
        }

        self.backendConfig.operationQueue.addOperation(operation)
    }

}

// MARK: - Private

private extension IAMAPI {

    func verifyAndCacheIDToken(_ idToken: String) {
        jwtVerifier.verify(idToken: idToken) { [weak self] claims in
            if let claims {
                self?.sessionManager.saveClaims(claims)
            }
        }
    }

}

// @unchecked because class is not `final` (it could be mocked).
extension IAMAPI: @unchecked Sendable {}
