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
import XCTest

#if os(iOS)
import UIKit

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

    /// A "Selected tab" rule is a state rule, and a package card is allowed to carry one directly.
    /// Every other component resolves its overrides against the paywall's state snapshot; the card
    /// has to as well, or the rule is silently dead.
    func testStateVisibilityOverrideIsResolvedFromTheStateSnapshot() throws {
        let viewModel = try Self.makeViewModel(
            component: Self.stateGatedComponent(package: TestData.monthlyPackage),
            package: TestData.monthlyPackage
        )

        XCTAssertTrue(
            Self.visible(viewModel, stateValues: ["selected_tier": .string("monthly")]),
            "The rule matches the current state, so the card is revealed."
        )
    }

    /// The declared default stands in until the store publishes a value, so the first frame resolves
    /// the same way every other component does.
    func testStateVisibilityOverrideFallsBackToDeclaredDefault() throws {
        let viewModel = try Self.makeViewModel(
            component: Self.stateGatedComponent(package: TestData.monthlyPackage),
            package: TestData.monthlyPackage
        )

        XCTAssertTrue(
            Self.visible(viewModel, stateDefaults: ["selected_tier": .string("monthly")]),
            "With no published value the declared default decides the rule."
        )
    }

    /// A control rather than a regression: this passes with or without the state hand-off, since the
    /// card's hidden base stands either way. It is here so the two above cannot be satisfied by
    /// simply revealing every card.
    func testStateVisibilityOverrideKeepsCardHiddenForAnotherState() throws {
        let viewModel = try Self.makeViewModel(
            component: Self.stateGatedComponent(package: TestData.monthlyPackage),
            package: TestData.monthlyPackage
        )

        XCTAssertFalse(
            Self.visible(viewModel, stateValues: ["selected_tier": .string("annual")]),
            "The rule does not match, so the card stays hidden."
        )
    }

    func testInjectedHapticFeedbackPreparesOnAppearWhenEnabled() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly")
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)
        var prepareCount = 0
        let spy = SelectionHapticFeedback(action: {}, prepare: { prepareCount += 1 })

        let (window, _) = Self.host(Self.hostable(viewModel: viewModel, package: package, spy: spy))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertGreaterThanOrEqual(
            prepareCount, 1,
            "The haptic feedback injected via the environment should be prepared on appear when enabled."
        )
    }

    func testInjectedHapticFeedbackDoesNotPrepareWhenDisabled() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly"),
            hapticFeedbackEnabled: false
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)
        var prepareCount = 0
        let spy = SelectionHapticFeedback(action: {}, prepare: { prepareCount += 1 })

        let (window, _) = Self.host(Self.hostable(viewModel: viewModel, package: package, spy: spy))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertEqual(
            prepareCount, 0,
            "Haptic feedback should not be prepared when the package has it disabled."
        )
    }

    func testHapticFeedbackEnabledDefaultsToTrueWhenComponentOmitsIt() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly")
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)

        XCTAssertTrue(viewModel.hapticFeedbackEnabled)
    }

    func testHapticFeedbackEnabledReflectsExplicitFalse() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly"),
            hapticFeedbackEnabled: false
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)

        XCTAssertFalse(viewModel.hapticFeedbackEnabled)
    }

    func testShouldTriggerHapticFeedback_whenSelectionChangesAndEnabled_returnsTrue() {
        let origin = TestData.weeklyPackage
        let destination = TestData.monthlyPackage

        XCTAssertTrue(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: origin,
                destination: destination,
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenSelectionUnchanged_returnsFalse() {
        let package = TestData.monthlyPackage

        XCTAssertFalse(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: package,
                destination: package,
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenDisabled_returnsFalseEvenIfSelectionChanges() {
        let origin = TestData.weeklyPackage
        let destination = TestData.monthlyPackage

        XCTAssertFalse(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: origin,
                destination: destination,
                hapticFeedbackEnabled: false
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenOriginIsNilAndSelectionChanges_returnsTrue() {
        let destination = TestData.monthlyPackage

        XCTAssertTrue(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: nil,
                destination: destination,
                hapticFeedbackEnabled: true
            )
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageComponentViewTests {

    /// A card hidden in the base and revealed only while the tier state reads `monthly`, which is
    /// the shape a "Selected tab" rule takes when it is authored on the package itself.
    static func stateGatedComponent(package: Package) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            visible: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly"),
            overrides: [
                .init(
                    extendedConditions: [
                        .state(operator: .equals, name: "selected_tier", value: .string("monthly"))
                    ],
                    properties: .init(visible: true)
                )
            ]
        )
    }

    /// Calls the card's own visibility resolution the way `PackageComponentView.body` does, so a
    /// test can vary just the state snapshot.
    static func visible(
        _ viewModel: PackageComponentViewModel,
        stateValues: [String: PaywallComponent.ConditionValue] = [:],
        stateDefaults: [String: PaywallComponent.ConditionValue] = [:]
    ) -> Bool {
        return viewModel.visible(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            stateValues: stateValues,
            stateDefaults: stateDefaults
        )
    }

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
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light,
            ancestorResolvers: []
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

    static func hostable(
        viewModel: PackageComponentViewModel,
        package: Package,
        spy: SelectionHapticFeedback
    ) -> some View {
        let packageContext = PackageContext(
            package: package,
            variableContext: .init(packages: [package])
        )
        return PackageComponentView(viewModel: viewModel, onDismiss: {})
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
            .environment(\.selectionHapticFeedback, spy)
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
