//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentViewModelTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PurchaseButtonComponentViewModelTests: TestCase {

    private static let urlLid = "url_lid"

    // MARK: - Environment

    func testCustomWebCheckoutUsesProductionEnvironment() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            envParam: "rc_env"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: false
        ))

        expect(self.queryItems(in: launch.url)["rc_env"]) == "production"
    }

    func testCustomWebCheckoutUsesSandboxEnvironment() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            envParam: "rc_env"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: true
        ))

        expect(self.queryItems(in: launch.url)["rc_env"]) == "sandbox"
    }

    // MARK: - Parameter names

    func testCustomWebCheckoutAddsAllConfiguredParameters() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            packageParam: "my_package",
            appUserIDParam: "my_user",
            envParam: "my_env"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: Self.packageContext(identifier: "monthly"),
            appUserID: "user_1",
            isSandbox: false
        ))

        expect(self.queryItems(in: launch.url)) == [
            "rc_source": "app",
            "my_user": "user_1",
            "my_env": "production",
            "my_package": "monthly"
        ]
    }

    func testCustomWebCheckoutWithNoConfiguredParametersOnlyAddsSource() throws {
        let viewModel = try self.makeViewModel(url: "https://example.com/checkout")

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: Self.packageContext(identifier: "monthly"),
            appUserID: "user_1",
            isSandbox: true
        ))

        expect(self.queryItems(in: launch.url)) == ["rc_source": "app"]
    }

    func testCustomWebCheckoutWithoutSelectedPackageOmitsPackageParameter() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            packageParam: "my_package",
            appUserIDParam: "my_user",
            envParam: "my_env"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: PackageContext(package: nil, variableContext: .init(packages: [])),
            appUserID: "user_1",
            isSandbox: false
        ))

        expect(self.queryItems(in: launch.url)) == [
            "rc_source": "app",
            "my_user": "user_1",
            "my_env": "production"
        ]
    }

    // MARK: - Encoding

    func testCustomWebCheckoutPercentEncodesValues() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            packageParam: "my package",
            appUserIDParam: "my_user",
            envParam: "my_env"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: Self.packageContext(identifier: "monthly&plan"),
            appUserID: "user+one@example.com",
            isSandbox: false
        ))

        let query = try XCTUnwrap(URLComponents(url: launch.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery)
        expect(query).to(contain("my_user=user%2Bone@example.com"))
        expect(query).to(contain("my%20package=monthly%26plan"))

        expect(self.queryItems(in: launch.url)) == [
            "rc_source": "app",
            "my_user": "user+one@example.com",
            "my_env": "production",
            "my package": "monthly&plan"
        ]
    }

    // MARK: - Existing URL contents

    func testCustomWebCheckoutPreservesExistingQueryItemsAndFragment() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout?campaign=summer&utm_source=email#section",
            appUserIDParam: "my_user"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: false
        ))

        let components = try XCTUnwrap(URLComponents(url: launch.url, resolvingAgainstBaseURL: false))
        expect(components.fragment) == "section"
        expect(self.queryItems(in: launch.url)) == [
            "campaign": "summer",
            "utm_source": "email",
            "rc_source": "app",
            "my_user": "user_1"
        ]
    }

    func testCustomWebCheckoutReplacesExistingParametersWithTheSameName() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout?rc_source=web&my_user=stale&keep=me",
            appUserIDParam: "my_user"
        )

        let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: false
        ))

        expect(self.queryItems(in: launch.url)) == [
            "keep": "me",
            "rc_source": "app",
            "my_user": "user_1"
        ]
    }

    func testCustomWebCheckoutIsStableAcrossCalls() throws {
        let viewModel = try self.makeViewModel(
            url: "https://example.com/checkout",
            packageParam: "my_package",
            appUserIDParam: "my_user",
            envParam: "my_env"
        )
        let packageContext = Self.packageContext(identifier: "monthly")

        let first = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: packageContext,
            appUserID: "user_1",
            isSandbox: false
        ))
        let second = try XCTUnwrap(viewModel.urlForWebCheckout(
            packageContext: packageContext,
            appUserID: "user_1",
            isSandbox: false
        ))

        expect(first.url) == second.url
    }

    func testCustomWebCheckoutWithMissingLocalizedUrlThrows() throws {
        expect {
            try self.makeViewModel(url: nil)
        }.to(throwError())
    }

    // MARK: - Bundled checkout (no WPL fallback)

    func testWebCheckoutDoesNotUseWebPurchaseLink() throws {
        let checkoutUrl = try XCTUnwrap(URL(string: "https://pay.rev.cat/checkout?foo=bar"))
        let viewModel = try self.makeViewModel(
            method: .webCheckout(.init()),
            webCheckoutUrl: checkoutUrl
        )

        expect(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: true
        )).to(beNil())
    }

    func testWebProductSelectionDoesNotUseWebPurchaseLink() throws {
        let checkoutUrl = try XCTUnwrap(URL(string: "https://pay.rev.cat/checkout?foo=bar"))
        let viewModel = try self.makeViewModel(
            method: .webProductSelection(.init()),
            webCheckoutUrl: checkoutUrl
        )

        expect(viewModel.urlForWebCheckout(
            packageContext: nil,
            appUserID: "user_1",
            isSandbox: true
        )).to(beNil())
    }

    // MARK: - Helpers

    private func queryItems(in url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return items.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }

    private func makeViewModel(
        url: String?,
        packageParam: String? = nil,
        appUserIDParam: String? = nil,
        envParam: String? = nil
    ) throws -> PurchaseButtonComponentViewModel {
        return try self.makeViewModel(
            method: .customWebCheckout(
                .init(
                    customUrl: .init(
                        url: Self.urlLid,
                        packageParam: packageParam,
                        appUserIDParam: appUserIDParam,
                        envParam: envParam
                    )
                )
            ),
            localizedUrl: url
        )
    }

    private func makeViewModel(
        method: PaywallComponent.PurchaseButtonComponent.Method,
        localizedUrl: String? = nil,
        webCheckoutUrl: URL? = nil
    ) throws -> PurchaseButtonComponentViewModel {
        let component = PaywallComponent.PurchaseButtonComponent(
            stack: .init(components: []),
            action: nil,
            method: method,
            name: nil
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let stackViewModel = StackComponentViewModel(
            component: component.stack,
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: uiConfigProvider
        )

        return try PurchaseButtonComponentViewModel(
            localizationProvider: .init(
                locale: .current,
                localizedStrings: localizedUrl.map { [Self.urlLid: .string($0)] } ?? [:]
            ),
            component: component,
            offering: .init(
                identifier: "test",
                serverDescription: "",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: webCheckoutUrl
            ),
            stackViewModel: stackViewModel
        )
    }

    private static func packageContext(identifier: String) -> PackageContext {
        let product = TestStoreProduct(
            localizedTitle: "PRO",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: "com.revenuecat.monthly",
            productType: .autoRenewableSubscription,
            localizedDescription: "Monthly subscription",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            locale: Locale(identifier: "en_US")
        )
        let package = Package(
            identifier: identifier,
            packageType: .monthly,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
        )

        return PackageContext(package: package, variableContext: .init(packages: [package]))
    }

}

#endif
