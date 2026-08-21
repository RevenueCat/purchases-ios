//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AuthenticationTests.swift
//
//  Created by RevenueCat on 8/13/26.

import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class AuthenticationTests: TestCase {

    private static let appUserID = "test-app-user-id"

    private var backend: MockBackend!
    private var identityManager: MockIdentityManager!
    private var operationDispatcher: MockOperationDispatcher!
    private var internalDelegate: MockInternalAuthenticatorDelegate!
    private var authenticationDelegate: MockAuthenticationDelegate!
    private var secureItemStorage: MockSecureItemStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.backend = MockBackend()
        self.identityManager = MockIdentityManager(mockAppUserID: Self.appUserID,
                                                   mockDeviceCache: MockDeviceCache())
        self.operationDispatcher = MockOperationDispatcher()
        self.internalDelegate = MockInternalAuthenticatorDelegate()
        self.authenticationDelegate = MockAuthenticationDelegate()
        self.secureItemStorage = MockSecureItemStorage()
    }

    /// - Parameters:
    ///   - tokenManagerEnabled: mirrors whether IAM identities are enabled; when `true`,
    ///   `identifyCurrentUser` should refuse to provide an alias for the current user.
    private func makeAuthentication(
        tokenManagerEnabled: Bool = false,
        customEntitlementComputation: Bool = false
    ) -> Authentication {
        let tokenManager = TokenManager(enabled: tokenManagerEnabled, storage: self.secureItemStorage)
        let systemInfo = MockSystemInfo(finishTransactions: false,
                                        customEntitlementsComputation: customEntitlementComputation)

        let authentication = Authentication(backend: self.backend,
                                            identityManager: self.identityManager,
                                            tokenManager: tokenManager,
                                            operationDispatcher: self.operationDispatcher,
                                            systemInfo: systemInfo,
                                            internalDelegate: self.internalDelegate)
        authentication.delegate = self.authenticationDelegate
        return authentication
    }

    // MARK: - identifyCurrentUser(as: String, completion:)

    func testIdentifyCurrentUserWithStringSucceedsAndNotifiesInternalDelegate() throws {
        let authentication = self.makeAuthentication()
        let expectedInfo = try CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-in-user"))
        self.identityManager.mockLogInResult = .success((expectedInfo, true))

        var receivedInfo: CustomerInfo?
        var receivedCreated: Bool?
        var receivedError: PublicError?

        authentication.identifyCurrentUser(as: Self.appUserID) { info, created, error in
            receivedInfo = info
            receivedCreated = created
            receivedError = error
        }

        expect(receivedInfo) == expectedInfo
        expect(receivedCreated) == true
        expect(receivedError).to(beNil())
        expect(self.identityManager.invokedLogInParametersList) == [Self.appUserID]
        expect(self.internalDelegate.invokedAuthenticatorDidLogIn) == true
        expect(self.internalDelegate.invokedAuthenticatorDidLogInParametersList.last) == expectedInfo
    }

    func testIdentifyCurrentUserWithStringFailureDoesNotNotifyInternalDelegate() {
        let authentication = self.makeAuthentication()
        let backendError = BackendError.networkError(.offlineConnection())
        self.identityManager.mockLogInResult = .failure(backendError)

        var receivedInfo: CustomerInfo?
        var receivedCreated: Bool?
        var receivedError: PublicError?

        authentication.identifyCurrentUser(as: Self.appUserID) { info, created, error in
            receivedInfo = info
            receivedCreated = created
            receivedError = error
        }

        expect(receivedInfo).to(beNil())
        expect(receivedCreated) == false
        expect(receivedError).to(matchError(backendError.asPurchasesError))
        expect(self.internalDelegate.invokedAuthenticatorDidLogIn) == false
    }

    func testIdentifyCurrentUserWithStringTrimsWhitespaceBeforeLoggingIn() throws {
        let authentication = self.makeAuthentication()
        let info = try XCTUnwrap(CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-in-user")))
        self.identityManager.mockLogInResult = .success((info, true))
        let untrimmedAppUserID = "  \(Self.appUserID)  "

        authentication.identifyCurrentUser(as: untrimmedAppUserID) { _, _, _ in }

        expect(self.identityManager.invokedLogInParametersList) == [Self.appUserID]
    }

    func testIdentifyCurrentUserWithStringReturnsUnsupportedErrorWhenTokenManagerIsEnabled() {
        let authentication = self.makeAuthentication(tokenManagerEnabled: true)

        var receivedError: PublicError?
        authentication.identifyCurrentUser(as: Self.appUserID) { _, _, error in
            receivedError = error
        }

        expect(receivedError).to(matchError(ErrorCode.unsupportedError))
        expect(self.identityManager.invokedLogIn) == false
        expect(self.internalDelegate.invokedAuthenticatorDidLogIn) == false
    }

    // MARK: - identifyCurrentUser(as: StaticString, completion:) [deprecated]

    @available(*, deprecated)
    func testIdentifyCurrentUserWithStaticStringLogsDeprecationWarningAndDelegatesToStringOverload() throws {
        let authentication = self.makeAuthentication()
        let info = try XCTUnwrap(CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-in-user")))
        self.identityManager.mockLogInResult = .success((info, true))

        authentication.identifyCurrentUser(as: "static-user-id") { _, _, _ in }

        self.logger.verifyMessageWasLogged(Strings.identity.logging_in_with_static_string, level: .warn)
        expect(self.identityManager.invokedLogInParametersList) == ["static-user-id"]
    }

    // MARK: - identifyCurrentUser(as: String) async

    func testIdentifyCurrentUserAsyncReturnsCustomerInfoAndCreated() async throws {
        let authentication = self.makeAuthentication()
        let expectedInfo = try CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-in-user"))
        self.identityManager.mockLogInResult = .success((expectedInfo, true))
        let appUserID = Self.appUserID

        let result = try await authentication.identifyCurrentUser(as: appUserID)

        expect(result.customerInfo) == expectedInfo
        expect(result.created) == true
    }

    func testIdentifyCurrentUserAsyncPropagatesFailure() async {
        let authentication = self.makeAuthentication()
        let backendError = BackendError.networkError(.offlineConnection())
        self.identityManager.mockLogInResult = .failure(backendError)
        let appUserID = Self.appUserID

        do {
            _ = try await authentication.identifyCurrentUser(as: appUserID)
            fail("Expected identifyCurrentUser to throw")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
    }

    @available(*, deprecated)
    func testIdentifyCurrentUserAsyncWithStaticStringLogsDeprecationWarning() async throws {
        let authentication = self.makeAuthentication()
        self.identityManager.mockLogInResult = .success(
            (try CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-in-user")), true)
        )

        _ = try await authentication.identifyCurrentUser(as: "static-user-id")

        self.logger.verifyMessageWasLogged(Strings.identity.logging_in_with_static_string, level: .warn)
    }

    // MARK: - logOut(completion:)

    func testLogOutCallsLogOutWithUserInitiatedTrueAndForwardsResult() throws {
        let authentication = self.makeAuthentication()
        self.identityManager.mockLogOutError = nil
        let expectedInfo = try CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-out-user"))
        self.internalDelegate.stubbedAuthenticatorDidChangeIdentityResult = .success(expectedInfo)

        var receivedInfo: CustomerInfo?
        var receivedError: PublicError?

        authentication.logOut { info, error in
            receivedInfo = info
            receivedError = error
        }

        expect(receivedInfo) == expectedInfo
        expect(receivedError).to(beNil())
        expect(self.identityManager.invokedLogOutCount) == 1
        expect(self.internalDelegate.invokedAuthenticatorDidChangeIdentity) == true
    }

    func testLogOutForwardsIdentityManagerErrorToCompletionAndDoesNotChangeIdentity() {
        let authentication = self.makeAuthentication()
        let logOutError = BackendError.networkError(.offlineConnection()).asPurchasesError
        self.identityManager.mockLogOutError = logOutError

        var receivedError: PublicError?
        authentication.logOut { _, error in
            receivedError = error
        }

        expect(receivedError).to(matchError(logOutError))
        expect(self.internalDelegate.invokedAuthenticatorDidChangeIdentity) == false
    }

    // MARK: - logOut(userInitiated:completion:) - custom entitlement computation

    func testLogOutReturnsFeatureNotAvailableErrorWhenCustomEntitlementComputationIsEnabled() {
        let authentication = self.makeAuthentication(customEntitlementComputation: true)

        var receivedInfo: CustomerInfo?
        var receivedError: PublicError?
        authentication.logOut { info, error in
            receivedInfo = info
            receivedError = error
        }

        expect(receivedInfo).to(beNil())
        expect(receivedError).to(matchError(ErrorCode.featureNotAvailableInCustomEntitlementsComputationMode))
        expect(self.identityManager.invokedLogOut) == false
    }

    func testLogOutReportsErrorToDelegateWhenCustomEntitlementComputationIsEnabledAndNotUserInitiated() {
        let authentication = self.makeAuthentication(customEntitlementComputation: true)

        authentication.logOut(userInitiated: false, completion: nil)

        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterError) == true
        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterErrorParametersList.last).to(
            matchError(ErrorCode.featureNotAvailableInCustomEntitlementsComputationMode)
        )
    }

    func testLogOutDoesNotReportErrorToDelegateWhenCustomEntitlementComputationIsEnabledAndUserInitiated() {
        let authentication = self.makeAuthentication(customEntitlementComputation: true)

        authentication.logOut(userInitiated: true, completion: nil)

        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterError) == false
    }

    // MARK: - logOut(userInitiated:completion:) - identityManager failure

    func testLogOutReportsErrorToDelegateWhenIdentityManagerFailsAndNotUserInitiated() {
        let authentication = self.makeAuthentication()
        self.identityManager.mockLogOutError = BackendError.networkError(.offlineConnection()).asPurchasesError

        authentication.logOut(userInitiated: false, completion: nil)

        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterError) == true
    }

    func testLogOutDoesNotReportErrorToDelegateWhenIdentityManagerFailsAndUserInitiated() {
        let authentication = self.makeAuthentication()
        self.identityManager.mockLogOutError = BackendError.networkError(.offlineConnection()).asPurchasesError

        authentication.logOut(userInitiated: true, completion: nil)

        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterError) == false
    }

    // MARK: - logOut() async

    func testLogOutAsyncReturnsCustomerInfo() async throws {
        let authentication = self.makeAuthentication()
        self.identityManager.mockLogOutError = nil
        let expectedInfo = try CustomerInfo(data: Self.customerInfoData(originalAppUserId: "logged-out-user"))
        self.internalDelegate.stubbedAuthenticatorDidChangeIdentityResult = .success(expectedInfo)

        let result = try await authentication.logOut()

        expect(result) == expectedInfo
    }

    func testLogOutAsyncPropagatesFailure() async {
        let authentication = self.makeAuthentication()
        let logOutError = BackendError.networkError(.offlineConnection()).asPurchasesError
        self.identityManager.mockLogOutError = logOutError

        do {
            _ = try await authentication.logOut()
            fail("Expected logOut to throw")
        } catch {
            expect(error).to(matchError(logOutError))
        }
    }

    // MARK: - reportAuthenticationError(_:)

    func testReportAuthenticationErrorDoesNothingWhenNoDelegateIsSet() {
        let authentication = self.makeAuthentication()
        authentication.delegate = nil

        authentication.reportAuthenticationError(NSError(domain: "AuthenticationTests", code: 1))

        expect(self.operationDispatcher.invokedDispatchOnMainThread) == false
        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterError) == false
    }

    func testReportAuthenticationErrorNotifiesTheDelegateOnTheMainThread() {
        let authentication = self.makeAuthentication()
        let error = NSError(domain: "AuthenticationTests", code: 1)

        authentication.reportAuthenticationError(error)

        expect(self.operationDispatcher.invokedDispatchOnMainThread) == true
        expect(self.authenticationDelegate.invokedAuthenticatorDidEncounterErrorParametersList) == [error]
    }

}

private extension AuthenticationTests {

    static func customerInfoData(originalAppUserId: String) -> [String: Any] {
        return [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": originalAppUserId,
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ] as [String: Any]
        ]
    }

}
