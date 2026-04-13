//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentViewTests.swift
//
//  Created by RevenueCat on 3/26/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import UIKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PackageComponentViewTests: TestCase {

    func testSelectedVisibilityOverrideUsesRenderedPackageContext() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly"),
            overrides: [
                .init(conditions: [.selected], properties: .init(visible: false))
            ]
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)
        let packageContext = PackageContext(
            package: package,
            variableContext: .init(packages: [package])
        )

        let view = PackageComponentView(viewModel: viewModel, onDismiss: {})
            .environmentObject(
                IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                )
            )
            .environmentObject(
                PaywallPromoOfferCache(
                    subscriptionHistoryTracker: SubscriptionHistoryTracker()
                )
            )
            .environmentObject(packageContext)
            .environment(\.selectedPackageId, package.identifier)
            .environment(\.screenCondition, .compact)
            .environment(\.componentViewState, .default)
            .environment(\.safeAreaInsets, EdgeInsets())

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(
            hostedView.containsText("Monthly"),
            "A package-level .selected visibility override should be evaluated against the rendered package."
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageComponentViewTests {

    static func makeViewModel(
        component: PaywallComponent.PackageComponent,
        package: Package
    ) throws -> PackageComponentViewModel {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [package],
            webCheckoutUrl: nil
        )
        let localizationProvider = LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()

        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            heroSafeAreaInfo: nil,
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light
        )

        return PackageComponentViewModel(
            component: component,
            offering: offering,
            stackViewModel: stackViewModel,
            hasPurchaseButton: false,
            uiConfigProvider: uiConfigProvider
        )
    }

    static func makePackageStack(label: String) -> PaywallComponent.StackComponent {
        return PaywallComponent.StackComponent(
            components: [
                .text(
                    PaywallComponent.TextComponent(
                        text: label,
                        color: .init(light: .hex("#000000"))
                    )
                )
            ]
        )
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(
            rootView: view
                .frame(width: 300, height: 200)
        )
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 200)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return (window, controller.view)
    }

}

private extension UIView {

    func containsText(_ text: String) -> Bool {
        if let label = self as? UILabel, label.text == text {
            return true
        }

        if self.accessibilityLabel == text {
            return true
        }

        return self.subviews.contains { $0.containsText(text) }
    }

}

#endif
