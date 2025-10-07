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
        let manager = makeSUT(backendResponse: .success(
            HealthReport(
                status: .passed,
                projectId: "test_project",
                appId: "test_app",
                checks: []
            )
        ), canMakePayments: false)

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthy(.notAuthorizedToMakePayments))
    }

    func testHealthReportReturnsUnhealthyForInvalidAPIKey() async {
        let manager = makeSUT(backendResponse: .failure(BackendError.networkError(.errorResponse(
            .init(code: .invalidAPIKey, originalCode: 0),
            .forbidden
        ))))

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthy(.invalidAPIKey))
    }

    func testHealthReportReturnsUnhealthyForUnknownBackendError() async {
        let manager = makeSUT(backendResponse: .failure(BackendError.networkError(
            .errorResponse(
                .init(code: .unknownError, originalCode: 0),
                .internalServerError
            )
        )))

        let report = await manager.healthReport()

        expect(report.status).to(beUnhealthyWithUnknownError())
    }

    func testHealthReportIsNotLoggedForUnhealthyErrors() async {
        let manager = makeSUT(backendResponse: .failure(BackendError.networkError(
            .errorResponse(
                .init(code: .unknownError, originalCode: 0),
                .internalServerError
            )
        )))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("SDK Configuration is not valid", level: .error)
    }

    func testHealthReportReturnsUnhealthyForNonBackendError() async {
        let manager = makeSUT(backendResponse: .failure(BackendError.networkError(.errorResponse(
            .init(code: .unknownError, originalCode: 0),
            .internalServerError
        ))))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

        let report = await manager.healthReport()

        expect(report.status).to(beHealthyWithWarnings())
        if case let .healthy(warnings) = report.status {
            expect(warnings).to(haveCount(1))
            expect(warnings[0]).to(beInvalidProducts())
        }
    }

    func testLogSDKHealthReportOutcomeLogsErrorForUnhealthyStatus() async {
        let manager = makeSUT(
            backendResponse: .failure(
                BackendError.networkError(
                    .errorResponse(.init(code: .invalidAPIKey, originalCode: 0), .forbidden)
                )
            )
        )

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
        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged(
            "https://app.revenuecat.com/projects/test_project/product-catalog/offerings",
            level: .error
        )
    }

    func testLogSDKHealthReportOutcomeIncludesProductIssuesSection() async {
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
                    ),
                    ProductHealthReport(
                        identifier: "test_product_3",
                        title: "Test Product 3",
                        status: .needsAction,
                        description: "Product needs action in App Store Connect."
                    )
                ])))
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Product Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged(
            "✅ test_product (Test Product): Available for production purchases.",
            level: .info
        )
        self.logger.verifyMessageWasLogged(
            "❌ test_product_2: Product not found in App Store Connect.",
            level: .info
        )
        self.logger.verifyMessageWasLogged(
            """
            ⚠️ test_product_3 (Test Product 3): This product's status (Product needs action in App Store Connect.) \
            requires you to take action in App Store Connect before using it in production purchases.
            """,
            level: .info
        )
    }

    func testLogSDKHealthReportOutcomeIncludesOfferingIssuesSection() async {
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
                                ),
                                PackageHealthReport(
                                    identifier: "test_package_2",
                                    title: "Test Package 2",
                                    status: .notFound,
                                    description: "Package not found in App Store Connect.",
                                    productIdentifier: "test_product_2",
                                    productTitle: "Test Product 2"
                                )
                            ],
                            status: .warning
                        ),
                        OfferingHealthReport(
                            identifier: "test_offering_2",
                            packages: [
                                PackageHealthReport(
                                    identifier: "test_package_3",
                                    title: "Test Package 3",
                                    status: .needsAction,
                                    description: "Package needs action in App Store Connect.",
                                    productIdentifier: "test_product_3",
                                    productTitle: "Test Product 3"
                                )
                            ],
                            status: .warning
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Offering Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("✅ test_offering", level: .info)
        self.logger.verifyMessageWasNotLogged(
            "✅ test_package (test_product): Available for production purchases.",
            level: .info
        )
        self.logger.verifyMessageWasLogged("⚠️ test_offering_2", level: .info)
        self.logger.verifyMessageWasLogged(
            """
            ❌ test_package_2 (test_product_2): Product not found in App Store Connect. You need to create a product \
            with identifier: 'test_product_2' in App Store Connect to use it for production purchases.
            """,
            level: .info
        )
        self.logger.verifyMessageWasLogged(
            """
            ⚠️ test_package_3 (test_product_3): This product's status (Package needs action in App Store Connect.) \
            requires you to take action in App Store Connect before using it in production purchases.
            """,
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

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("Product Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("Offering Issues:", level: .info)
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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

        let manager = makeSUT(backendResponse: .success(healthReport))

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

    func testLogSDKHealthReportOutcomeDoesNotIncludeValidProducts() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .passed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "valid_product_1",
                        title: "Valid Product 1",
                        status: .valid,
                        description: "Available for production purchases."
                    ),
                    ProductHealthReport(
                        identifier: "valid_product_2",
                        title: "Valid Product 2",
                        status: .valid,
                        description: "Available for production purchases."
                    )
                ])))
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("Product Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("valid_product_1", level: .info)
        self.logger.verifyMessageWasNotLogged("valid_product_2", level: .info)
    }

    func testLogSDKHealthReportOutcomeDoesNotIncludeValidOfferings() async {
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
                            identifier: "valid_offering",
                            packages: [
                                PackageHealthReport(
                                    identifier: "valid_package",
                                    title: "Valid Package",
                                    status: .valid,
                                    description: "Available for production purchases.",
                                    productIdentifier: "valid_product",
                                    productTitle: "Valid Product"
                                )
                            ],
                            status: .passed
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("Offering Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("valid_offering", level: .info)
        self.logger.verifyMessageWasNotLogged("valid_package", level: .info)
    }

    func testLogSDKHealthReportOutcomeDoesNotIncludeValidOfferingMessages() async {
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
                                    identifier: "valid_package",
                                    title: "Valid Package",
                                    status: .valid,
                                    description: "Available for production purchases.",
                                    productIdentifier: "valid_product",
                                    productTitle: "Valid Product"
                                ),
                                PackageHealthReport(
                                    identifier: "invalid_package",
                                    title: "Invalid Package",
                                    status: .notFound,
                                    description: "Package not found in App Store Connect.",
                                    productIdentifier: "invalid_product",
                                    productTitle: "Invalid Product"
                                )
                            ],
                            status: .passed
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasNotLogged("valid_package", level: .info)
    }

    func testLogSDKHealthReportOutcomeIncludesAllProductStatusesExceptValid() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .passed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "valid_product",
                        title: "Valid Product",
                        status: .valid,
                        description: "Available for production purchases."
                    ),
                    ProductHealthReport(
                        identifier: "not_found_product",
                        title: "Not Found Product",
                        status: .notFound,
                        description: "Product not found in App Store Connect."
                    ),
                    ProductHealthReport(
                        identifier: "needs_action_product",
                        title: "Needs Action Product",
                        status: .needsAction,
                        description: "Product needs action in App Store Connect."
                    ),
                    ProductHealthReport(
                        identifier: "action_in_progress_product",
                        title: "Action In Progress Product",
                        status: .actionInProgress,
                        description: "Action in progress for this product."
                    ),
                    ProductHealthReport(
                        identifier: "could_not_check_product",
                        title: "Could Not Check Product",
                        status: .couldNotCheck,
                        description: "Could not validate product status."
                    ),
                    ProductHealthReport(
                        identifier: "unknown_product",
                        title: "Unknown Product",
                        status: .unknown,
                        description: "Unknown product status."
                    )
                ])))
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Product Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("valid_product", level: .info)
        self.logger.verifyMessageWasLogged("❌ not_found_product", level: .info)
        self.logger.verifyMessageWasLogged("⚠️ needs_action_product", level: .info)
        self.logger.verifyMessageWasLogged("⏳ action_in_progress_product", level: .info)
        self.logger.verifyMessageWasLogged("❓ could_not_check_product", level: .info)
        self.logger.verifyMessageWasLogged("❓ unknown_product", level: .info)
    }

    func testLogSDKHealthReportOutcomeIncludesAllOfferingStatusesExceptPassed() async {
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
                            identifier: "passed_offering",
                            packages: [],
                            status: .passed
                        ),
                        OfferingHealthReport(
                            identifier: "failed_offering",
                            packages: [],
                            status: .failed
                        ),
                        OfferingHealthReport(
                            identifier: "warning_offering",
                            packages: [],
                            status: .warning
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("Offering Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("passed_offering", level: .info)
        self.logger.verifyMessageWasLogged("❌ failed_offering", level: .info)
        self.logger.verifyMessageWasLogged("⚠️ warning_offering", level: .info)
    }

    func testLogSDKHealthReportOutcomeShowsCleanMessageWhenAllProductsAndOfferingsAreValid() async {
        let healthReport = HealthReport(
            status: .passed,
            projectId: "test_project",
            appId: "test_app",
            checks: [
                HealthCheck(name: .products, status: .passed, details: .products(ProductsCheckDetails(products: [
                    ProductHealthReport(
                        identifier: "valid_product",
                        title: "Valid Product",
                        status: .valid,
                        description: "Available for production purchases."
                    )
                ]))),
                HealthCheck(
                    name: .offeringsProducts,
                    status: .passed,
                    details: .offeringsProducts(OfferingsCheckDetails(offerings: [
                        OfferingHealthReport(
                            identifier: "valid_offering",
                            packages: [
                                PackageHealthReport(
                                    identifier: "valid_package",
                                    title: "Valid Package",
                                    status: .valid,
                                    description: "Available for production purchases.",
                                    productIdentifier: "valid_product",
                                    productTitle: "Valid Product"
                                )
                            ],
                            status: .passed
                        )
                    ]))
                )
            ]
        )

        let manager = makeSUT(backendResponse: .success(healthReport))

        await manager.logSDKHealthReportOutcome()

        self.logger.verifyMessageWasLogged("✅ RevenueCat SDK is configured correctly", level: .info)
        self.logger.verifyMessageWasNotLogged("Product Issues:", level: .info)
        self.logger.verifyMessageWasNotLogged("Offering Issues:", level: .info)
    }
}

// MARK: - Builder Methods

fileprivate extension SDKHealthManagerTests {
    private func makeSUT(
        backendResponse: Result<HealthReport, BackendError>,
        canMakePayments: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SDKHealthManager {
        let backend = MockBackend()
        backend.healthReportRequestResponse = backendResponse
        let manager = SDKHealthManager(
            backend: backend,
            identityManager: MockIdentityManager(mockAppUserID: "app_user_id", mockDeviceCache: .init()),
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
