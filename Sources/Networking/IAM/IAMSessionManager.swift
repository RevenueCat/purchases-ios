//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMSessionManager.swift
//
//  Created by RevenueCat.

import Foundation

/// Thread-safe manager for IAM authentication sessions.
///
/// Stores the current session (access token, refresh token, id token) and
/// handles transparent token refresh when a request receives a 401 response.
final class IAMSessionManager: @unchecked Sendable {

    private let lock = Lock()
    private var _currentSession: IAMSession?
    private var _currentClaims: IDTokenClaims?
    private var _pendingRefreshCallbacks: [(Bool) -> Void] = []
    private var _isRefreshing = false

    private let apiKey: String
    private let baseURL: URL
    private let keychainStorage: IAMKeychainStorage?

    init(apiKey: String, baseURL: URL, keychainStorage: IAMKeychainStorage? = nil) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.keychainStorage = keychainStorage
        // Restore any session persisted during a previous app run.
        self._currentSession = keychainStorage?.load()
    }

    // MARK: - Session Access

    var currentSession: IAMSession? {
        self.lock.perform { _currentSession }
    }

    var accessToken: String? {
        self.lock.perform { _currentSession?.accessToken }
    }

    var hasSession: Bool {
        self.lock.perform { _currentSession != nil }
    }

    /// Whether the current session was established via anonymous login.
    /// Returns `true` if no session exists (unauthenticated state is treated as anonymous).
    var isAnonymous: Bool {
        self.lock.perform { _currentSession?.isAnonymous ?? true }
    }

    func saveSession(_ session: IAMSession) {
        self.lock.perform { _currentSession = session }
        self.keychainStorage?.save(session)
    }

    func saveClaims(_ claims: IDTokenClaims) {
        let updatedSession: IAMSession? = self.lock.perform {
            _currentClaims = claims
            guard let session = _currentSession else { return nil }
            let updated = IAMSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                idToken: session.idToken,
                isAnonymous: session.isAnonymous,
                subject: claims.subject
            )
            _currentSession = updated
            return updated
        }
        if let session = updatedSession {
            self.keychainStorage?.save(session)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .rcIAMClaimsUpdated, object: nil)
        }
    }

    /// The verified claims from the most recent ID token, if available.
    var idTokenClaims: IDTokenClaims? {
        self.lock.perform { _currentClaims }
    }

    func clearSession() {
        self.lock.perform {
            _currentSession = nil
            _currentClaims = nil
        }
        self.keychainStorage?.clear()
    }

    // MARK: - Token Refresh

    /// Refreshes the access token using the stored refresh token.
    ///
    /// If a refresh is already in progress, the callback is queued until the ongoing
    /// refresh completes (preventing duplicate refresh requests).
    ///
    /// - Parameter completion: Called with `true` if the token was refreshed successfully,
    ///   `false` if refresh failed or no refresh token is available.
    func refreshSessionIfPossible(completion: @escaping (Bool) -> Void) {
        let (shouldRefresh, refreshToken, currentIsAnonymous) = self.lock.perform {
            () -> (Bool, String?, Bool) in
            if _isRefreshing {
                _pendingRefreshCallbacks.append(completion)
                return (false, nil, false)
            }
            guard let token = _currentSession?.refreshToken else {
                return (false, nil, false)
            }
            _isRefreshing = true
            return (true, token, _currentSession?.isAnonymous ?? true)
        }

        guard shouldRefresh else {
            // If not refreshing (no refresh token), call back with failure.
            // If already refreshing, the callback was queued above.
            let isRefreshing = self.lock.perform { _isRefreshing }
            if !isRefreshing {
                completion(false)
            }
            return
        }

        guard let refreshToken else {
            completion(false)
            return
        }

        self.performTokenRefresh(refreshToken: refreshToken,
                                 isAnonymous: currentIsAnonymous) { [weak self] newSession in
            guard let self else {
                completion(false)
                return
            }
            let callbacks = self.lock.perform { () -> [(Bool) -> Void] in
                self._isRefreshing = false
                if let session = newSession {
                    self._currentSession = session
                } else {
                    // Refresh failed — clear the session so callers know auth is gone
                    self._currentSession = nil
                }
                let pending = self._pendingRefreshCallbacks
                self._pendingRefreshCallbacks = []
                return pending
            }
            // Persist the outcome outside the lock.
            if let session = newSession {
                self.keychainStorage?.save(session)
            } else {
                self.keychainStorage?.clear()
            }
            let success = newSession != nil
            completion(success)
            for cb in callbacks { cb(success) }
        }
    }

    // MARK: - Private

    private func performTokenRefresh(refreshToken: String,
                                     isAnonymous: Bool,
                                     completion: @escaping (IAMSession?) -> Void) {
        guard let url = URL(string: "/auth/token", relativeTo: self.baseURL) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")

        let body = TokenRefreshBody(refreshToken: refreshToken)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            completion(nil)
            return
        }
        request.httpBody = bodyData

        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard
                let data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let json = try? JSONDecoder().decode(IAMAuthResponse.self, from: data)
            else {
                completion(nil)
                return
            }
            completion(IAMSession(
                accessToken: json.accessToken,
                // Keep the existing refresh token if a new one wasn't provided
                refreshToken: json.refreshToken ?? refreshToken,
                idToken: json.idToken,
                isAnonymous: isAnonymous
            ))
        }.resume()
    }

}

// MARK: - Notifications

extension Notification.Name {

    /// Posted on the main thread whenever the IAM ID token claims are updated.
    static let rcIAMClaimsUpdated = Notification.Name("RevenueCat.IAMClaimsUpdated")

}

// MARK: - Private types

private extension IAMSessionManager {

    struct TokenRefreshBody: Encodable {

        let grantType = "refresh_token"
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case grantType = "grant_type"
            case refreshToken = "refresh_token"
        }

    }

}
