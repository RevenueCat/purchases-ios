//
//  Authenticator.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/30/26.
//

import Foundation

/// The delegate for ``Authentication``, responsible for responding to authentication errors that occuring
/// during passive SDK use.
///
/// Typically, getting an authentication error means that the SDK needs a new ``Identity`` token provided
/// to the ``Authentication.logIn(using:)`` method
@_spi(Experimental)
@objc(RCPurchasesAuthenticationDelegate)
public protocol AuthenticationDelegate: NSObjectProtocol {
    func authenticatorDidEncounterError(_ error: PublicError)
}

internal protocol InternalAuthenticatorDelegate: AnyObject {
    func authenticatorDidLogIn(info: CustomerInfo?, error: PublicError?)
    func authenticatorDidChangeIdentity(completion: @escaping (Result<CustomerInfo, PublicError>) -> Void)
}

/// A namespace for providing authentication-related functionality to the ``Purchases`` instance
@_spi(Experimental)
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
    public weak var delegate: AuthenticationDelegate?
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

        tokenManager.reportError = { [weak self] in
            self?.reportAuthenticationError($0)
        }
    }

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
        self.identityManager.logIn(appUserID: normalizedAppUserID) { result in
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.value?.info, result.value?.created ?? false, result.error?.asPublicError)
            }
            self.ongoingUserInitiatedRequestCount.decrement()

            guard case .success = result else {
                return
            }

            self.internalDelegate?.authenticatorDidLogIn(info: result.value?.info, error: result.error?.asPublicError)
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

    @_disfavoredOverload
    public func identifyCurrentUser(as appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await withUnsafeThrowingContinuation { continuation in
            self.identifyCurrentUser(as: appUserID, completion: { customerInfo, created, error in
                continuation.resume(with: Result(customerInfo, error)
                    .map { ($0, created) })
            })
        }
    }

    public func logIn(using token: Identity) async throws -> CustomerInfo {
        return try await withUnsafeThrowingContinuation { continuation in
            self.logIn(using: token, completion: { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            })
        }
    }

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
        guard self.backend.token.enabled else {
            let error = NewErrorUtils.unsupportedError(message: "Token login requires .with(iamEnabled: true)")
            completion?(nil, error.asPublicError)
            if userInitiated == false { self.reportAuthenticationError(error.asPublicError) }
            return
        }

        if userInitiated { self.ongoingUserInitiatedRequestCount.increment() }
        self.identityManager.logIn(identity: identity) { result in
            if userInitiated { self.ongoingUserInitiatedRequestCount.decrement() }

            if let completion {
                self.operationDispatcher.dispatchOnMainThread {
                    completion(result.value?.info, result.error?.asPublicError)
                }
            }

            switch result {
            case .success(let result):
                self.internalDelegate?.authenticatorDidLogIn(info: result.info,
                                                             error: nil)
            case .failure(let error):
                if userInitiated == false {
                    self.reportAuthenticationError(error.asPublicError)
                }
            }

        }

    }

    internal func logOut(userInitiated: Bool, completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
            let error = NewErrorUtils.featureNotAvailableInCustomEntitlementsComputationModeError().asPublicError
            completion?(nil, error)
            if userInitiated == false { self.reportAuthenticationError(error) }
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
                    self.reportAuthenticationError(error.asPublicError)
                }
            } else {
                self.internalDelegate?.authenticatorDidChangeIdentity { result in
                    completion?(result.value, result.error)
                }
            }
        }
    }

    internal func reportAuthenticationError(_ error: PublicError) {
        guard let delegate else { return }

        // if we currently have user initiated requests going, then skip reporting this error via the delegate
        if self.ongoingUserInitiatedRequestCount.value > 0 { return }

        self.operationDispatcher.dispatchOnMainThread {
            delegate.authenticatorDidEncounterError(error)
        }
    }

}
