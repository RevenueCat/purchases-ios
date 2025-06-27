//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKHealthManagerTests.swift
//
//  Created by Pol Piella Abadia on 12/19/24.

import Nimble
import XCTest

@testable import RevenueCat

class SDKHealthManagerTests: TestCase {
    func testHealthReportReturnsUnhealthyWhenCannotMakePayments() async {
        let manager = makeSUT(request: {
            return HealthReport(
                status: .passed,
                projectId: "test_project",
                appId: "test_app",
                checks: []
            )
        }, canMakePayments: false)

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthy(.notAuthorizedToMakePayments))
    }

    func testHealthReportReturnsUnhealthyForInvalidAPIKey() async {
        let manager = makeSUT {
            throw BackendError.networkError(.errorResponse(
                .init(code: .invalidAPIKey, originalCode: 0),
                .forbidden
            ))
        }

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthy(.invalidAPIKey))
    }

    func testHealthReportReturnsUnhealthyForUnknownBackendError() async {
        let manager = makeSUT {
            throw BackendError.networkError(
                .errorResponse(
                    .init(code: .unknownError, originalCode: 0),
                    .internalServerError
                )
            )
        }

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthyWithUnknownError())
    }

    func testHealthReportReturnsUnhealthyForNonBackendError() async {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        let manager = makeSUT {
            throw testError
        }

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthyWithUnknownError())
    }

    func testHealthReportWithValidHealthReport() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .passed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product",
                        title: "Test Product",
                        status: .valid,
                        description: "Available for production purchases."
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        let report = await manager.healthReport()

        expect(report.status).to(beHealthy())
        expect(report.projectId) == "test_project"
        expect(report.appId) == "test_app"
        expect(report.products).to(haveCount(1))
        expect(report.products[0].identifier) == "test_product"
        expect(report.products[0].status) == .valid
    }

    func testHealthReportWithFailedCheck() async {
        let healthReport = HealthReport(
            status: .failed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .apiKey, status: .failed)
            ]
        )

        let manager = makeSUT { healthReport }

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthy(.invalidAPIKey))
        expect(report.projectId) == "test_project"
        expect(report.appId) == "test_app"
    }

    func testHealthReportWithWarnings() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .warning, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product",
                        title: "Test Product",
                        status: .needsAction,
                        description: "Product needs action in App Store Connect"
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        let report = await manager.healthReport()

        expect(report.status).to(beHealthyWithWarnings())
        if case let .healthy(warnings) = report.status {
            expect(warnings).to(haveCount(1))
            expect(warnings[0]).to(beInvalidProducts())
        }
    }

    func testLogSDKHealthReportOutcomeLogsErrorForUnhealthyStatus() async {
        let manager = makeSUT {
            throw BackendError.networkError(.errorResponse(.init(code: .invalidAPIKey, originalCode: 0), .forbidden))
        }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("SDK Configuration is not valid", level: .error)
        self.logger.verifyMessageWasLogged("API key is not valid", level: .error)
    }

    func testLogSDKHealthReportOutcomeLogsInfoForHealthyStatus() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: []
        )
        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("SDK is configured correctly", level: .info)
    }

    func testLogSDKHealthReportOutcomeLogsWarningForHealthyWithWarningsStatus() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .warning, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product",
                        title: "Test Product",
                        status: .needsAction,
                        description: "Product needs action in App Store Connect."
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "SDK is configured correctly, but contains some issues you might want to address",
            level: .warn
        )
        self.logger.verifyMessageWasLogged("Warnings:", level: .warn)
    }

    func testLogSDKHealthReportOutcomeIncludesActionURLForInvalidBundleId() async {
        let healthReport = HealthReport(
            status: .failed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .bundleId, status: .failed, details: .bundleId(BundleIdCheckDetails(
                    sdkBundleId: "com.test.sdk",
                    appBundleId: "com.test.app"
                )))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "https://app.revenuecat.com/projects/test_project/apps/test_app",
            level: .error
        )
        self.logger.verifyMessageWasLogged(
            "Please visit the RevenueCat website to resolve the issue",
            level: .error
        )
    }

    func testLogSDKHealthReportOutcomeIncludesActionURLForInvalidProducts() async {
        let healthReport = HealthReport(
            status: .failed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .failed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product",
                        title: "Test Product",
                        status: .notFound,
                        description: "Product not found in App Store Connect."
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "https://app.revenuecat.com/projects/test_project/product-catalog/products",
            level: .error
        )
    }

    func testLogSDKHealthReportOutcomeIncludesActionURLForOfferingConfiguration() async {
        let healthReport = HealthReport(
            status: .failed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .offerings, status: .failed)
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "https://app.revenuecat.com/projects/test_project/product-catalog/offerings",
            level: .error
        )
    }

    func testLogSDKHealthReportOutcomeIncludesProductsSection() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .passed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product",
                        title: "Test Product",
                        status: .valid,
                        description: "Available for production purchases."
                    ),
                    ProductHealthReport(
                        identifier: "test_product_2",
                        title: nil,
                        status: .notFound,
                        description: "Product not found in App Store Connect."
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Products Status:", level: .info)
        self.logger.verifyMessageWasLogged(
            "✅ test_product (Test Product): Available for production purchases.",
            level: .info
        )
        self.logger.verifyMessageWasLogged(
            "❌ test_product_2: Product not found in App Store Connect.",
            level: .info
        )
    }

    func testLogSDKHealthReportOutcomeIncludesOfferingsSection() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(
                    name: .offeringsProducts,
                    status: .passed,
                    details: .offeringsProducts(OfferingsCheckDetails(offerings: [
                        OfferingHealthReport(
                            identifier: "test_offering",
                            packages: [
                                PackageHealthReport(
                                    identifier: "test_package",
                                    title: "Test Package",
                                    status: .valid,
                                    description: "Available for production purchases.",
                                    productIdentifier: "test_product",
                                    productTitle: "Test Product"
                                )
                            ],
                            status: .passed
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Offerings Status:", level: .info)
        self.logger.verifyMessageWasLogged("✅ test_offering", level: .info)
        self.logger.verifyMessageWasLogged(
            "✅ test_package (test_product): Available for production purchases.",
            level: .info
        )
    }

    func testLogSDKHealthReportOutcomeDoesNotIncludeEmptySections() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: []
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("Products Status:", level: .info)
        self.logger.verifyMessageWasNotLogged("Offerings Status:", level: .info)
    }

    func testLogSDKHealthReportOutcomeLogsSpecialMessageWhenNoAppStoreConnectCredentials() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .warning, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product_1",
                        title: "Test Product 1",
                        status: .couldNotCheck,
                        description: "Could not validate product status due to App Store Connect API issues"
                    ),
                    ProductHealthReport(
                        identifier: "test_product_2",
                        title: "Test Product 2",
                        status: .couldNotCheck,
                        description: "Could not validate product status due to App Store Connect API issues"
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "We could not validate your SDK's configuration and check your product statuses in App Store Connect.",
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            "Error: Could not validate product status due to App Store Connect API issues",
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            """
            If you want to check if your SDK is configured correctly, please check your App Store Connect \
            credentials in RevenueCat, make sure your App Store Connect App exists and try again:
            """,
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            "https://app.revenuecat.com/projects/test_project/apps/test_app#scroll=app-store-connect-api",
            level: .warn
        )
    }

    func testLogSDKHealthReportOutcomeLogsNoAppStoreCredentialsWarningWithNoProjectAndAppId() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: nil,
            appId: nil,
            checks: [
                HealthCheck(name: .products, status: .warning, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "test_product_1",
                        title: "Test Product 1",
                        status: .couldNotCheck,
                        description: "Could not validate product status due to App Store Connect API issues"
                    ),
                    ProductHealthReport(
                        identifier: "test_product_2",
                        title: "Test Product 2",
                        status: .couldNotCheck,
                        description: "Could not validate product status due to App Store Connect API issues"
                    )
                ])))
            ]
        )

        let manager = makeSUT { healthReport }

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "We could not validate your SDK's configuration and check your product statuses in App Store Connect.",
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            "Error: Could not validate product status due to App Store Connect API issues",
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            """
            If you want to check if your SDK is configured correctly, please check your App Store Connect \
            credentials in RevenueCat, make sure your App Store Connect App exists and try again:
            """,
            level: .warn
        )
        self.logger.verifyMessageWasNotLogged("https://app.revenuecat.com/projects/", level: .warn)
    }
}

// MARK: - Builder Methods

fileprivate extension SDKHealthManagerTests {
    private func makeSUT(
        request: @escaping @Sendable () async throws -> HealthReport,
        canMakePayments: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SDKHealthManager {
        let manager = SDKHealthManager(
            healthReportRequest: request,
            paymentAuthorizationProvider: .mock(canMakePayments: canMakePayments)
        )

        addTeardownBlock { [weak manager] in
            XCTAssertNil(
                manager,
                file: file,
                line: line
            )
        }

        return manager
    }
}

// MARK: - Custom Matchers

fileprivate extension SDKHealthManagerTests {
    private func beHealthy() -> Matcher<PurchasesDiagnostics.SDKHealthStatus> {
        return Matcher { actualExpression in
            let message = ExpectationMessage.expectedActualValueTo("be healthy")

            guard let actual = try actualExpression.evaluate() else {
                return MatcherResult(status: .fail, message: message.appendedBeNilHint())
            }

            switch actual {
            case .healthy:
                return MatcherResult(status: .matches, message: message)
            case .unhealthy:
                return MatcherResult(status: .fail, message: message.appended(details: "was unhealthy"))
            }
        }
    }

    private func beHealthyWithWarnings() -> Matcher<PurchasesDiagnostics.SDKHealthStatus> {
        return Matcher { actualExpression in
            let message = ExpectationMessage.expectedActualValueTo("be healthy with warnings")

            guard let actual = try actualExpression.evaluate() else {
                return MatcherResult(status: .fail, message: message.appendedBeNilHint())
            }

            switch actual {
            case let .healthy(warnings):
                if warnings.isEmpty {
                    return MatcherResult(
                        status: .fail,
                        message: message.appended(details: "was healthy without warnings")
                    )
                } else {
                    return MatcherResult(status: .matches, message: message)
                }
            case .unhealthy:
                return MatcherResult(status: .fail, message: message.appended(details: "was unhealthy"))
            }
        }
    }

    private func beUnhealthy(
        _ error: PurchasesDiagnostics.SDKHealthError
    ) -> Matcher<PurchasesDiagnostics.SDKHealthStatus> {
        return Matcher { [error] actualExpression in
            let message = ExpectationMessage.expectedActualValueTo("be unhealthy with error \(error)")

            guard let actual = try actualExpression.evaluate() else {
                return MatcherResult(status: .fail, message: message.appendedBeNilHint())
            }

            switch actual {
            case .healthy:
                return MatcherResult(status: .fail, message: message.appended(details: "was healthy"))
            case let .unhealthy(actualError):
                return self.compareUnhealthyErrors(expected: error, actual: actualError, message: message)
            }
        }
    }

    private func compareUnhealthyErrors(
        expected: PurchasesDiagnostics.SDKHealthError,
        actual: PurchasesDiagnostics.SDKHealthError,
        message: ExpectationMessage
    ) -> MatcherResult {
        switch (expected, actual) {
        case (.invalidAPIKey, .invalidAPIKey),
             (.noOfferings, .noOfferings),
             (.notAuthorizedToMakePayments, .notAuthorizedToMakePayments):
            return MatcherResult(status: .matches, message: message)
        case let (.invalidBundleId(expected), .invalidBundleId(actual)):
            if expected == actual {
                return MatcherResult(status: .matches, message: message)
            } else {
                return MatcherResult(status: .fail, message: message.appended(details: "bundle ID mismatch"))
            }
        case let (.invalidProducts(expected), .invalidProducts(actual)):
            if expected.count == actual.count {
                return MatcherResult(status: .matches, message: message)
            } else {
                return MatcherResult(
                    status: .fail,
                    message: message.appended(details: "products count mismatch")
                )
            }
        case let (.offeringConfiguration(expected), .offeringConfiguration(actual)):
            if expected.count == actual.count {
                return MatcherResult(status: .matches, message: message)
            } else {
                return MatcherResult(
                    status: .fail,
                    message: message.appended(details: "offerings count mismatch")
                )
            }
        case (.unknown, .unknown):
            return MatcherResult(status: .matches, message: message)
        default:
            return MatcherResult(
                status: .fail,
                message: message.appended(details: "was unhealthy with different error \(actual)")
            )
        }
    }

    private func beInvalidProducts() -> Matcher<PurchasesDiagnostics.SDKHealthError> {
        return Matcher { actualExpression in
            let message = ExpectationMessage.expectedActualValueTo("be invalid products error")

            guard let actual = try actualExpression.evaluate() else {
                return MatcherResult(status: .fail, message: message.appendedBeNilHint())
            }

            switch actual {
            case .invalidProducts:
                return MatcherResult(status: .matches, message: message)
            default:
                return MatcherResult(status: .fail, message: message.appended(details: "was \(actual)"))
            }
        }
    }

    private func beUnhealthyWithUnknownError() -> Matcher<PurchasesDiagnostics.SDKHealthStatus> {
        return Matcher { actualExpression in
            let message = ExpectationMessage.expectedActualValueTo("be unhealthy with unknown error")

            guard let actual = try actualExpression.evaluate() else {
                return MatcherResult(status: .fail, message: message.appendedBeNilHint())
            }

            switch actual {
            case .healthy:
                return MatcherResult(status: .fail, message: message.appended(details: "was healthy"))
            case let .unhealthy(error):
                if case .unknown = error {
                    return MatcherResult(status: .matches, message: message)
                } else {
                    return MatcherResult(
                        status: .fail,
                        message: message.appended(details: "was unhealthy with error \(error)")
                    )
                }
            }
        }
    }
}

// MARK: - Mocks

fileprivate extension PaymentAuthorizationProvider {
    static func mock(canMakePayments: Bool = true) -> PaymentAuthorizationProvider {
        return PaymentAuthorizationProvider(
            isAuthorized: { canMakePayments }
        )
    }
}
