//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsV2ViewContextPackageTests.swift

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit
#endif

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallsV2ViewContextPackageTests: TestCase {

    // MARK: - makeSelectedPackageContext

    @MainActor
    func testMakeSelectedPackageContextUsesProvidedDefault() throws {
        let state = try Self.makePaywallState(defaultPackage: TestData.monthlyPackage)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            defaultPackage: TestData.monthlyPackage,
            workflowPackages: nil,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package?.identifier) == TestData.monthlyPackage.identifier
    }

    @MainActor
    func testMakeSelectedPackageContextReturnsNilWhenNoDefault() throws {
        let state = try Self.makePaywallState(defaultPackage: nil)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            defaultPackage: nil,
            workflowPackages: nil,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package).to(beNil())
    }

    // MARK: - effectiveDefaultPackage

    func testEffectiveDefaultPackagePrefersContextPackageWhenResolvableInStep() {
        // When a user selected a package on the previous step, it should carry forward
        // and take priority over the workflow default on the new step.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: [TestData.monthlyPackage, TestData.annualPackage]
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultOnPackagelessStep() {
        // On a truly packageless step, contextPackage can't be resolved —
        // the workflow default applies so price/period variables still render.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: nil,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: []
        )
        expect(result?.identifier) == TestData.monthlyPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultWhenNoContextCarried() {
        // On the first workflow step there's no prior selection (contextPackage is nil),
        // so the workflow default applies as the initial display/variable-resolution package.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.annualPackage,
            contextPackage: nil,
            stepPackages: [TestData.monthlyPackage, TestData.annualPackage]
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsNilWhenBothDefaultsAreNil() {
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: nil,
            workflowDefaultPackage: nil,
            contextPackage: nil,
            stepPackages: []
        )
        expect(result).to(beNil())
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultWhenContextNotInStep() {
        // contextPackage exists but isn't in the step's offering (cross-offering).
        // The workflow default should apply for display on this step.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: [TestData.weeklyPackage]
        )
        expect(result?.identifier) == TestData.monthlyPackage.identifier
    }

    func testEffectiveDefaultPackageWorkflowOverridesPageDefault() {
        // Workflow default takes priority over the page's own default.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.annualPackage
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    // MARK: - validatedContextPackage

    func testValidatedContextPackageReturnsPackageWhenFoundInOffering() {
        let packages = [TestData.monthlyPackage, TestData.annualPackage]

        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: packages)

        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testValidatedContextPackageReturnsNilWhenNotInOffering() {
        let packages = [TestData.monthlyPackage]

        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: packages)

        expect(result).to(beNil())
    }

    func testValidatedContextPackageReturnsNilWhenContextPackageIsNil() {
        let packages = [TestData.monthlyPackage, TestData.annualPackage]

        let result = PaywallsV2View.validatedContextPackage(nil, in: packages)

        expect(result).to(beNil())
    }

    func testValidatedContextPackageReturnsNilWhenOfferingIsEmpty() {
        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: [])

        expect(result).to(beNil())
    }

    #if os(iOS)
    @MainActor
    func testRootViewDismissingSelectionSheetRestoresCarriedDefaultPackage() throws {
        let packages = [TestData.monthlyPackage, TestData.annualPackage]
        let packageContext = PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: packages)
        )
        let purchaseHandler = PurchaseHandler.default()
        let view = RootView(
            viewModel: try Self.makeRootViewModelForSheetDismissRegressionTest(packages: packages),
            onDismiss: {},
            defaultPackage: TestData.annualPackage
        )
        .environmentObject(packageContext)
        .environmentObject(purchaseHandler)
        .environment(\.workflowPackageContext, .init(selectedPackage: TestData.monthlyPackage, packages: packages))
        .environment(\.safeAreaInsets, EdgeInsets())
        .frame(width: 300, height: 400)

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        let rootButtons = hostedView.allSubviews(of: UIButton.self)
        XCTAssertEqual(rootButtons.count, 1, "Expected one root button that opens the selection sheet.")

        rootButtons[0].sendActions(for: .touchUpInside)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let sheetButtons = hostedView.allSubviews(of: UIButton.self)
        XCTAssertGreaterThanOrEqual(sheetButtons.count, 2, "Expected the sheet dismiss button to be rendered.")

        sheetButtons[sheetButtons.count - 1].sendActions(for: .touchUpInside)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.annualPackage.identifier,
            "Dismissing the sheet without changing packages must keep the carried page default."
        )
    }
    #endif

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallsV2ViewContextPackageTests {

    @MainActor
    static func makePaywallState(defaultPackage: Package?) throws -> PaywallState {
        var factory = ViewModelFactory()

        if let pkg = defaultPackage {
            factory.packageValidator.add(PackageValidator.PackageInfo(
                package: pkg,
                isSelectedByDefault: true,
                isStaticallyVisible: true,
                promotionalOfferProductCode: nil
            ))
        }

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        let rootViewModel = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try makeUIConfigProvider(),
            colorScheme: .light
        )

        let packageInfos: [PaywallState.PackageInfo] = defaultPackage.map { [($0, nil)] } ?? []

        return PaywallState(
            componentsConfig: componentsConfig,
            viewModelFactory: factory,
            packageInfos: packageInfos,
            rootViewModel: rootViewModel,
            showZeroDecimalPlacePrices: true
        )
    }

    static func makeUIConfigProvider() throws -> UIConfigProvider {
        let json = """
        {
          "app": { "colors": {}, "fonts": {} },
          "localizations": {}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: data)
        return UIConfigProvider(uiConfig: uiConfig)
    }

    static var mockOffering: Offering {
        .init(
            identifier: "test_offering",
            serverDescription: "Test Offering",
            metadata: [:],
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    #if os(iOS)
    static func makeRootViewModelForSheetDismissRegressionTest(
        packages: [Package]
    ) throws -> RootViewModel {
        let offering = Offering(
            identifier: "test_offering",
            serverDescription: "Test Offering",
            metadata: [:],
            availablePackages: packages,
            webCheckoutUrl: nil
        )
        let localizationProvider: LocalizationProvider = .init(
            locale: .current,
            localizedStrings: [
                "open_sheet": .string("Open Sheet"),
                "close_sheet": .string("Close Sheet")
            ]
        )
        var factory = ViewModelFactory()

        return try factory.toRootViewModel(
            componentsConfig: .init(
                stack: .init(components: [
                    .button(
                        .init(
                            action: .navigateTo(
                                destination: .sheet(
                                    sheet: .init(
                                        id: "sheet",
                                        name: "picker",
                                        stack: .init(components: [
                                            .button(
                                                .init(
                                                    action: .navigateBack,
                                                    stack: Self.makeButtonStack(text: "close_sheet")
                                                )
                                            )
                                        ]),
                                        backgroundBlur: false,
                                        size: .init(width: .fill, height: .fit)
                                    )
                                )
                            ),
                            stack: Self.makeButtonStack(text: "open_sheet")
                        )
                    )
                ]),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#FFFFFF")))
            ),
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        )
    }

    static func makeButtonStack(text: String) -> PaywallComponent.StackComponent {
        .init(
            components: [
                .text(
                    .init(
                        text: text,
                        color: .init(light: .hex("#000000"))
                    )
                )
            ]
        )
    }

    @MainActor
    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 400)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return (window, controller.view)
    }
    #endif

}

#if os(iOS)
private extension UIView {

    func allSubviews<T: UIView>(of type: T.Type) -> [T] {
        let directMatches = self.subviews.compactMap { $0 as? T }
        let nestedMatches = self.subviews.flatMap { $0.allSubviews(of: type) }

        return directMatches + nestedMatches
    }

}
#endif

#endif
