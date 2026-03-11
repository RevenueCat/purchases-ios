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
    private var _pendingRefreshCallbacks: [(Bool) -> Void] = []
    private var _isRefreshing = false

    private let apiKey: String
    private let baseURL: URL

    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
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

    func saveSession(_ session: IAMSession) {
        self.lock.perform { _currentSession = session }
    }

    func clearSession() {
        self.lock.perform {
            _currentSession = nil
        }
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
        let (shouldRefresh, refreshToken) = self.lock.perform { () -> (Bool, String?) in
            if _isRefreshing {
                _pendingRefreshCallbacks.append(completion)
                return (false, nil)
            }
            guard let token = _currentSession?.refreshToken else {
                return (false, nil)
            }
            _isRefreshing = true
            return (true, token)
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

        self.performTokenRefresh(refreshToken: refreshToken) { [weak self] newSession in
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
            let success = newSession != nil
            completion(success)
            for cb in callbacks { cb(success) }
        }
    }

    // MARK: - Private

    private func performTokenRefresh(refreshToken: String, completion: @escaping (IAMSession?) -> Void) {
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
                idToken: json.idToken
            ))
        }.resume()
    }

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
