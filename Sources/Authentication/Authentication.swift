//
//  Authentication.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/30/26.
//

import Foundation

/// The delegate for ``Authentication``, responsible for responding to authentication errors that occur
/// during passive SDK use.
///
/// Typically, getting an authentication error means that the SDK needs a new ``Identity`` token provided
/// to the ``Authentication.logIn(using:)`` method
@_spi(Internal)
@objc(RCPurchasesAuthenticationDelegate)
public protocol AuthenticationDelegate: NSObjectProtocol {

    /// The SDK encountered an unrecoverable authentication error while performing other operations
    ///
    /// This method is invoked when an attempt to refresh the session tokens fails, and the error corresponds
    /// to that error. Therefore, a single call into the SDK may result in *two* errors being reported. For example,
    /// if a call to ``Purchases.customerInfo()`` attempts causes the SDK to refresh its session tokens
    /// and that attempt fails, then this delegate method is invoked with the error from attempting to refresh
    /// the tokens, and the overall call to `customerInfo()` reports that the overall operation failed.
    ///
    /// This method is *not* invoked when ``Authentication.logIn(using:)`` or
    /// ``Authentication.logOut()`` fail, as both of those methods report any failures directly.
    ///
    /// When this method is invoked, all access tokens previously sent to ``authenticatorDidUpdateAccessToken(_:)``
    /// should be assumed to be invalid.
    ///
    /// - Parameter error: The ``PublicError`` indicating why authentication has failed
    func authenticatorDidEncounterError(_ error: PublicError)

    /// The SDK has updated the current user's access token
    ///
    /// This token can be used to communicate directly with the RevenueCat backend on behalf of the current user.
    ///
    /// - Parameter newAccessToken: The new access token, or `nil` if authentication failed.
    @objc optional func authenticatorDidUpdateAccessToken(_ newAccessToken: String?)
}

internal enum IdentityChangeReason: Equatable {
    case logIn
    case logOut
    case identified
}

internal protocol InternalAuthenticatorDelegate: AnyObject {
    func authenticatorDidChangeIdentity(reason: IdentityChangeReason,
                                        didHandle: @escaping (Result<CustomerInfo, PublicError>?) -> Void)
}

/// A namespace for providing authentication-related functionality to the ``Purchases`` instance
@_spi(Internal)
@objc(RCPurchasesAuthentication)
public final class Authentication: NSObject {

    private let backend: Backend
    private let identityManager: IdentityManager
    private let tokenManager: TokenManager
    private let operationDispatcher: OperationDispatcher
    private let systemInfo: SystemInfo
    internal weak var internalDelegate: InternalAuthenticatorDelegate?

    /// The delegate responsible for responding to any authentication errors that occur
    /// during operations that do not explicitly report their own errors.
    ///
    /// For example, if an authentication error occurs while updating the ``CustomerInfo``,
    /// that will be reported to the delegate.
    ///
    /// However, if an error occurs during an explicit ``logIn(using:)`` call, that will be reported
    /// via the corresponding completion handler (or thrown when called using `await`).
    ///
    /// - Warning: The delegate is not retained, so your app must retain a reference
    /// to the delegate to prevent it from being unintentionally deallocated.
    @objc public weak var delegate: AuthenticationDelegate?

    /// The access token for the currently authenticated user, if one exists.
    @objc public var currentAccessToken: String? { tokenManager.currentAccessToken }

    private let ongoingUserInitiatedRequestCount = Atomic(0)

    internal init(backend: Backend,
                  identityManager: IdentityManager,
                  tokenManager: TokenManager,
                  operationDispatcher: OperationDispatcher,
                  systemInfo: SystemInfo,
                  internalDelegate: InternalAuthenticatorDelegate? = nil) {
        self.backend = backend
        self.identityManager = identityManager
        self.tokenManager = tokenManager
        self.operationDispatcher = operationDispatcher
        self.systemInfo = systemInfo
        self.internalDelegate = internalDelegate
        super.init()

        tokenManager.reportTokenUpdate = { [weak self] in
            self?.reportAuthenticationResult($0)
        }
    }

    /// Provide an app-specific alias for the current user
    /// - Parameters:
    ///   - appUserID: The user's alias
    ///   - completion: A completion handler that is invoked with the updated ``CustomerInfo`` (if any),
    ///   a boolean indicating whether the user was created or restored, and an optional ``PublicError``
    @available(*, deprecated, message: """
    The appUserID passed to logIn is a constant string known at compile time.
    This is likely a programmer error. This ID is used to identify the current user.
    See https://docs.revenuecat.com/docs/user-ids for more information.
    """)
    public func identifyCurrentUser(as appUserID: StaticString,
                                    completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        Logger.warn(Strings.identity.logging_in_with_static_string)
        self.identifyCurrentUser(as: appUserID.description, completion: completion)
    }

    /// Provide an app-specific alias for the current user
    /// - Parameters:
    ///   - appUserID: The user's alias
    ///   - completion: A completion handler that is invoked with the updated ``CustomerInfo`` (if any),
    ///   a boolean indicating whether the user was created or restored, and an optional ``PublicError``
    @_disfavoredOverload
    @objc(identifyCurrentUserAsID:completion:)
    public func identifyCurrentUser(as appUserID: String,
                                    completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        self.identifyCurrentUser(as: appUserID, attributes: [:], completion: completion)
    }

    /// Provide an app-specific alias for the current user, setting `attributes` on them as part of the
    /// same request.
    /// - Parameters:
    ///   - appUserID: The user's alias
    ///   - attributes: Subscriber attributes to set on the user being identified
    ///   - completion: A completion handler that is invoked with the updated ``CustomerInfo`` (if any),
    ///   a boolean indicating whether the user was created or restored, and an optional ``PublicError``
    internal func identifyCurrentUser(as appUserID: String,
                                      attributes: [String: String],
                                      completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        guard tokenManager.enabled == false else {
            self.operationDispatcher.dispatchOnMainThread {
                let error = NewErrorUtils.unsupportedError(message:
                    "Providing an alias for the current user is unsupported when using IAM identities"
                )
                completion(nil, false, error.asPublicError)
            }
            return
        }

        let normalizedAppUserID = appUserID.trimmingWhitespacesAndNewLines

        self.ongoingUserInitiatedRequestCount.increment()
        self.identityManager.logIn(appUserID: normalizedAppUserID, attributes: attributes) { result in
            self.ongoingUserInitiatedRequestCount.decrement()

            self.operationDispatcher.dispatchOnMainThread {
                switch result {
                case .success(let values):
                    if let delegate = self.internalDelegate {
                        delegate.authenticatorDidChangeIdentity(reason: .identified) { _ in
                            completion(values.info, values.created, nil)
                        }
                    } else {
                        completion(values.info, values.created, nil)
                    }
                case .failure(let error):
                    completion(nil, false, error.asPublicError)
                }
            }
        }

    }

    /// Log in to the SDK using the provided identity token
    ///
    /// - Warning: If the SDK is already logged in using a non-anonymous identity,
    /// then a subsequent invocation of this method will *link* the two identities together.
    /// - Parameters:
    ///   - token: The ``Identity`` token for the user
    ///   - completion: A handler invoked after logging in has finished.
    @objc(logInUsingToken:completion:)
    public func logIn(using token: Identity, completion: @escaping (CustomerInfo?, PublicError?) -> Void) {
        self.logIn(using: token, userInitiated: true, completion: completion)
    }

    /// Log the current identity out
    ///
    /// Invoking this reverts the SDK to an anonymous identity
    /// - Parameter completion: A handler invoked after logging out has finished
    @objc
    public func logOut(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.logOut(userInitiated: true, completion: completion)
    }

    // MARK: - Async

    /// Provide an app-specific alias for the current user
    /// - Parameter appUserID: The user's alias
    /// - Returns: A tuple of the new ``CustomerInfo`` and a boolean indicating whether it was created or restored
    /// - Throws: an error if the alias could not be applied to the current user
    @available(*, deprecated, message: """
    The appUserID passed to logIn is a constant string known at compile time.
    This is likely a programmer error. This ID is used to identify the current user.
    See https://docs.revenuecat.com/docs/user-ids for more information.
    """)
    public func identifyCurrentUser(as appUserID: StaticString) async throws ->
        (customerInfo: CustomerInfo, created: Bool) {

        Logger.warn(Strings.identity.logging_in_with_static_string)
        return try await identifyCurrentUser(as: appUserID.description)
    }

    /// Provide an app-specific alias for the current user
    /// - Parameter appUserID: The user's alias
    /// - Returns: A tuple of the new ``CustomerInfo`` and a boolean indicating whether it was created or restored
    /// - Throws: an error if the alias could not be applied to the current user
    @_disfavoredOverload
    public func identifyCurrentUser(as appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await self.identifyCurrentUser(as: appUserID, attributes: [:])
    }

    /// Provide an app-specific alias for the current user, setting `attributes` on them as part of the
    /// same request.
    /// - Parameters:
    ///   - appUserID: The user's alias
    ///   - attributes: Subscriber attributes to set on the user being identified
    /// - Returns: A tuple of the new ``CustomerInfo`` and a boolean indicating whether it was created or restored
    /// - Throws: an error if the alias could not be applied to the current user
    internal func identifyCurrentUser(
        as appUserID: String,
        attributes: [String: String]
    ) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await withUnsafeThrowingContinuation { continuation in
            self.identifyCurrentUser(as: appUserID,
                                     attributes: attributes,
                                     completion: { customerInfo, created, error in
                continuation.resume(with: Result(customerInfo, error)
                    .map { ($0, created) })
            })
        }
    }

    /// Log out the current user and revert to an anonymous user identifier
    /// - Returns: The ``CustomerInfo`` of the anonymous user
    public func logOut() async throws -> CustomerInfo {
        return try await withUnsafeThrowingContinuation { continuation in
            self.logOut(completion: { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            })
        }
    }

    // MARK: - Internals

    internal func logInIfNeeded(completion: ((CustomerInfo?, PublicError?) -> Void)? = nil) {
        guard identityManager.needsIAMLogin else { return }
        self.logIn(using: .anonymous, userInitiated: false, completion: completion)
    }

    internal func logIn(using identity: Identity,
                        userInitiated: Bool,
                        completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        guard tokenManager.enabled else {
            let error = NewErrorUtils.unsupportedError(message: "Token login requires .with(iamEnabled: true)")
            self.operationDispatcher.dispatchOnMainThread {
                completion?(nil, error.asPublicError)
            }
            if userInitiated == false { self.reportAuthenticationResult(.failure(error.asPublicError)) }
            return
        }

        if userInitiated { self.ongoingUserInitiatedRequestCount.increment() }
        self.identityManager.logIn(identity: identity) { result in
            if userInitiated { self.ongoingUserInitiatedRequestCount.decrement() }

            switch result {
            case .success(let value):
                self.internalDelegate?.authenticatorDidChangeIdentity(reason: .logIn, didHandle: { _ in
                    completion?(value.info, nil)
                })
            case .failure(let error):
                if userInitiated == false {
                    self.reportAuthenticationResult(.failure(error.asPublicError))
                }
                if let completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, error.asPublicError)
                    }
                }
            }

        }

    }

    internal func logOut(userInitiated: Bool, completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
            let error = NewErrorUtils.featureNotAvailableInCustomEntitlementsComputationModeError().asPublicError
            self.operationDispatcher.dispatchOnMainThread {
                completion?(nil, error)
            }
            if userInitiated == false { self.reportAuthenticationResult(.failure(error)) }
            return
        }

        if userInitiated { self.ongoingUserInitiatedRequestCount.increment() }
        self.identityManager.logOut { error in
            if userInitiated { self.ongoingUserInitiatedRequestCount.decrement() }

            if let error {
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, error.asPublicError)
                    }
                }
                if userInitiated == false {
                    self.reportAuthenticationResult(.failure(error.asPublicError))
                }
            } else {
                self.operationDispatcher.dispatchOnMainThread {
                    guard let delegate = self.internalDelegate else {
                        // there was no error, but we also don't have a CustomerInfo object to provide
                        // that *should* be provided by the delegate, but for some unknown reason,
                        // the delegate is missing.
                        let error = NewErrorUtils.customerInfoError(withMessage: "Missing internal auth delegate")
                        completion?(nil, error.asPublicError)
                        return
                    }
                    delegate.authenticatorDidChangeIdentity(reason: .logOut) { result in
                        completion?(result?.value, result?.error)
                    }
                }
            }
        }
    }

    internal func reportAuthenticationResult(_ result: Result<String?, PublicError>) {
        guard let delegate else { return }

        switch result {
        case .success(let newAccessToken):
            guard tokenManager.enabled else { return }
            if let impl = delegate.authenticatorDidUpdateAccessToken {
                self.operationDispatcher.dispatchOnMainThread {
                    impl(newAccessToken)
                }
            }

        case .failure(let error):
            // if we currently have user initiated requests going, then skip reporting this error via the delegate
            if self.ongoingUserInitiatedRequestCount.value > 0 { return }

            self.operationDispatcher.dispatchOnMainThread {
                delegate.authenticatorDidEncounterError(error)
            }
        }
    }

}
