//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageValidatorTests.swift
//
//  Created by RevenueCat on 3/26/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PackageValidatorTests: TestCase {

    func testDefaultSelectedPackageSkipsStaticallyHiddenSelectedPackage() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            visible: false
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(in: Self.context())?.identifier,
            TestData.annualPackage.identifier
        )
    }

    func testDefaultSelectedPackageFallsBackToFirstStaticallyVisiblePackage() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: false
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            visible: true
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(in: Self.context())?.identifier,
            TestData.annualPackage.identifier
        )
    }

    func testDefaultSelectedPackageReturnsNilWhenAllPackagesAreStaticallyHidden() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            visible: false
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            visible: false
        ))

        XCTAssertNil(validator.defaultSelectedPackage(in: Self.context()))
    }

    // MARK: - Override-driven visibility

    /// The customer-reported bug: the default package is hidden by a `variable` rule, so nothing ends up
    /// selected even though another package is on screen.
    func testDefaultSelectedPackageSkipsPackageHiddenByVariableRule() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [
                Self.visibilityOverride(whenCanTrial: true, visible: false),
                Self.visibilityOverride(whenCanTrial: false, visible: true)
            ]
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )?.identifier,
            TestData.monthlyPackage.identifier
        )
    }

    /// The same paywall with the rule not matching: the authored default is visible and stays selected.
    func testDefaultSelectedPackageKeepsAuthoredDefaultWhenVariableRuleDoesNotMatch() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [
                Self.visibilityOverride(whenCanTrial: true, visible: false),
                Self.visibilityOverride(whenCanTrial: false, visible: true)
            ]
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(
                in: Self.context(customVariables: ["can_trial": .bool(true)])
            )?.identifier,
            TestData.annualPackage.identifier
        )
    }

    /// The fallback picks by document order, not by "first statically visible", so a package that is only
    /// visible because a rule turned it on is still eligible.
    func testFallbackPicksFirstOverrideVisiblePackageInDocumentOrder() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: false,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: true)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )?.identifier,
            TestData.weeklyPackage.identifier
        )
    }

    func testDefaultSelectedPackageReturnsNilWhenEveryPackageIsHiddenByRule() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))

        XCTAssertNil(
            validator.defaultSelectedPackage(
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )
        )
    }

    /// Intro-offer eligibility lands asynchronously, so selection has to resolve correctly both before and
    /// after it arrives.
    func testDefaultSelectedPackageSkipsPackageHiddenByIntroOfferRule() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [
                .init(
                    extendedConditions: [.introOfferCondition(operator: .equals, value: true)],
                    properties: .init(visible: false)
                )
            ]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage(
                in: Self.context(isEligibleForIntroOffer: { _ in true })
            )?.identifier,
            TestData.monthlyPackage.identifier
        )

        XCTAssertEqual(
            validator.defaultSelectedPackage(
                in: Self.context(isEligibleForIntroOffer: { _ in false })
            )?.identifier,
            TestData.annualPackage.identifier
        )
    }

    // MARK: - Reconciling a provisional selection

    /// End-to-end shape of the fix: the seed happens before the render environment exists, so it picks
    /// the trial card (an absent `can_trial` makes `can_trial = false` not match). Once the real context
    /// is known, reconciling moves the selection to the card that's actually on screen.
    func testReconcileMovesSelectionOffProvisionallySeededHiddenPackage() {
        let validator = Self.canTrialValidator()

        let seeded = validator.defaultSelectedPackage(in: .provisional)
        XCTAssertEqual(seeded?.identifier, TestData.annualPackage.identifier)

        let reconciled = validator.reconciledSelection(
            current: seeded,
            in: Self.context(customVariables: ["can_trial": .bool(false)])
        )
        XCTAssertEqual(reconciled?.identifier, TestData.monthlyPackage.identifier)
    }

    /// Nothing to do when the seeded package is visible: reconciling returns `nil` so the caller leaves
    /// the selection alone.
    func testReconcileIsANoOpWhenSelectionIsVisible() {
        let validator = Self.canTrialValidator()

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(true)])
            )
        )
    }

    /// A deliberate tap can't be discarded, because reconciling only fires for a package that isn't
    /// rendering, and the user can't tap a card that isn't on screen.
    func testReconcileKeepsAUserSelectionThatIsStillVisible() {
        let validator = Self.canTrialValidator()

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.monthlyPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )
        )
    }

    func testReconcileReturnsNilWhenNothingIsVisible() {
        let validator = PackageValidator()
        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )
        )
    }

    /// A paywall that swaps groups but reuses the same package identifier on both sides does NOT hit this
    /// bug, and this test pins down why: selection is compared by identifier
    /// (`PackageComponentView.packageViewState`), so a visible card carrying the authored default's
    /// identifier satisfies the selection and renders filled even though the authored card is hidden.
    ///
    /// This is why the customer's `family_plus_paywall2` was unaffected while `family_plus_paywall` broke,
    /// and it's the trap to avoid when authoring a fixture for this bug: the two groups need *distinct*
    /// package identifiers (the customer's were `family_annual` vs `family_annual_non-trial`).
    ///
    /// `weeklyPackage` stands in for `$rc_lifetime`, which `TestData` doesn't have. It's hidden in the
    /// `can_trial=false` case either way.
    func testDuplicatePackageIdentifierAcrossGroupsMasksAHiddenDefault() {
        let validator = PackageValidator()

        // Trial group: both hidden when can_trial=false.
        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        // Non-trial group: shown when can_trial=false. Note the second card reuses annualPackage.
        for package in [TestData.monthlyPackage, TestData.annualPackage] {
            validator.add(Self.makePackageInfo(
                package: package,
                isSelectedByDefault: false,
                visible: true,
                overrides: [
                    .init(
                        extendedConditions: [.introOfferCondition(operator: .equals, value: true)],
                        properties: .init(visible: false)
                    ),
                    Self.visibilityOverride(whenCanTrial: true, visible: false),
                    Self.visibilityOverride(whenCanTrial: false, visible: true)
                ]
            ))
        }

        // Intro-eligible as a fresh test-store user is: the later can_trial override still wins.
        let context = Self.context(
            customVariables: ["can_trial": .bool(false)],
            isEligibleForIntroOffer: { _ in true }
        )

        // Resolved from scratch the fallback would take the first visible card in document order...
        XCTAssertEqual(
            validator.defaultSelectedPackage(in: context)?.identifier,
            TestData.monthlyPackage.identifier
        )

        // ...but the seeded selection is `$rc_annual`, and a visible card still carries that identifier,
        // so there is nothing to reconcile and the selection stays put. No bug to observe here.
        let seeded = validator.defaultSelectedPackage(in: .provisional)
        XCTAssertEqual(seeded?.identifier, TestData.annualPackage.identifier)
        XCTAssertNil(validator.reconciledSelection(current: seeded, in: context))
    }

    /// The fixture shape that does reproduce the bug: the group shown when `can_trial=false` shares no
    /// package identifier with the authored default, so the seeded selection has nothing visible backing
    /// it and must be moved. This is what `default_package_hidden_by_visibility_rule.yaml` exercises.
    func testDistinctPackageIdentifiersAcrossGroupsReproduceTheBug() {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [
                .init(
                    extendedConditions: [.introOfferCondition(operator: .equals, value: true)],
                    properties: .init(visible: false)
                ),
                Self.visibilityOverride(whenCanTrial: true, visible: false),
                Self.visibilityOverride(whenCanTrial: false, visible: true)
            ]
        ))

        let context = Self.context(
            customVariables: ["can_trial": .bool(false)],
            isEligibleForIntroOffer: { _ in true }
        )

        let seeded = validator.defaultSelectedPackage(in: .provisional)
        XCTAssertEqual(seeded?.identifier, TestData.annualPackage.identifier)

        XCTAssertEqual(
            validator.reconciledSelection(current: seeded, in: context)?.identifier,
            TestData.monthlyPackage.identifier
        )
    }

    func testViewModelFactoryResolvesOverrideVisibilityForDefaultSelection() throws {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [TestData.monthlyPackage, TestData.annualPackage],
            webCheckoutUrl: nil
        )
        let localizationProvider = LocalizationProvider(
            locale: Locale(identifier: "en_US"),
            localizedStrings: ["package_label": .string("Package")]
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()
        let packageValidator = PackageValidator()

        _ = try factory.toViewModel(
            component: .package(
                Self.makePackageComponent(
                    packageID: TestData.annualPackage.identifier,
                    isSelectedByDefault: true,
                    visible: true,
                    overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
                )
            ),
            packageValidator: packageValidator,
            purchaseButtonCollector: nil,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        )

        _ = try factory.toViewModel(
            component: .package(
                Self.makePackageComponent(
                    packageID: TestData.monthlyPackage.identifier,
                    isSelectedByDefault: false,
                    visible: nil
                )
            ),
            packageValidator: packageValidator,
            purchaseButtonCollector: nil,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        )

        XCTAssertEqual(
            packageValidator.defaultSelectedPackage(
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )?.identifier,
            TestData.monthlyPackage.identifier
        )
    }

    /// Pins the recording order that "document order" means: a package nested inside another package's
    /// stack is recorded after its parent, because `ViewModelFactory` records before walking the stack.
    /// Recording after the walk would put the nested package first and hand the fallback to it.
    func testNestedPackageIsRecordedAfterItsParent() throws {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [TestData.monthlyPackage, TestData.annualPackage],
            webCheckoutUrl: nil
        )
        let factory = ViewModelFactory()
        let packageValidator = PackageValidator()

        let nested = Self.makePackageComponent(
            packageID: TestData.monthlyPackage.identifier,
            isSelectedByDefault: false,
            visible: nil
        )
        let outer = PaywallComponent.PackageComponent(
            packageID: TestData.annualPackage.identifier,
            isSelectedByDefault: false,
            visible: nil,
            applePromoOfferProductCode: nil,
            stack: .init(components: [.package(nested)])
        )

        _ = try factory.toViewModel(
            component: .package(outer),
            packageValidator: packageValidator,
            purchaseButtonCollector: nil,
            offering: offering,
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["package_label": .string("Package")]
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        )

        XCTAssertEqual(
            packageValidator.packages.map(\.identifier),
            [TestData.annualPackage.identifier, TestData.monthlyPackage.identifier]
        )

        // No package is selected by default, so the fallback takes the outer one.
        XCTAssertEqual(
            packageValidator.defaultSelectedPackage(in: Self.context())?.identifier,
            TestData.annualPackage.identifier
        )
    }

    // MARK: - Mixed page and tab scopes

    /// A package inside a tab must not stop the page from reconciling its own packages, and must not be
    /// picked as the replacement either: the user may be on a different tab.
    func testReconcileFallsBackToAPageScopedPackageWhenTabsAlsoHoldPackages() {
        let validator = Self.canTrialValidator()
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )?.identifier,
            TestData.monthlyPackage.identifier
        )
    }

    /// A tab can be rendering the current selection, so a page-level reconcile leaves it alone.
    func testReconcileKeepsASelectionThatOnlyATabRenders() {
        let validator = Self.canTrialValidator()
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.weeklyPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )
        )
    }

    /// Every package lives in a tab, so there is no page-level selection to resolve. The tabs reconcile
    /// their own, each against its own validator.
    func testReconcileIsANoOpWhenEveryPackageIsTabScoped() {
        let validator = PackageValidator()
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )
        )
    }

    /// A tab that isn't showing can carry the same identifier as the hidden page default. That copy is not
    /// on screen, so it must not count as proof the selection is still rendering.
    func testReconcileMovesOffAHiddenPageDefaultDuplicatedOnlyInATab() {
        let validator = Self.canTrialValidator()
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertEqual(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(false)])
            )?.identifier,
            TestData.monthlyPackage.identifier
        )
    }

    /// The mirror case: the page's own copy is visible, so the selection stays put.
    func testReconcileKeepsASelectionWhosePageCopyIsVisible() {
        let validator = Self.canTrialValidator()
        validator.addTabScoped(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        XCTAssertNil(
            validator.reconciledSelection(
                current: TestData.annualPackage,
                in: Self.context(customVariables: ["can_trial": .bool(true)])
            )
        )
    }

    // MARK: - Warnings

    /// `defaultSelectedPackage(in:)` is read from view bodies, so an unconditional warning repeats on
    /// every re-render. Each distinct warning is logged once per validator.
    func testHiddenDefaultWarningIsLoggedOnceForRepeatedResolutions() {
        let validator = Self.canTrialValidator()
        let context = Self.context(customVariables: ["can_trial": .bool(false)])

        for _ in 0..<5 {
            _ = validator.defaultSelectedPackage(in: context)
        }

        self.logger.verifyMessageWasLogged(
            Strings.paywall_default_package_not_visible(
                defaultPackage: TestData.annualPackage.identifier,
                selectedPackage: TestData.monthlyPackage.identifier
            ),
            level: .warn,
            expectedCount: 1
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageValidatorTests {

    /// The customer's shape, reduced to two packages: an annual card selected by default and hidden when
    /// `can_trial = false`, and a monthly card that only shows in that case.
    static func canTrialValidator() -> PackageValidator {
        let validator = PackageValidator()

        validator.add(Self.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
        ))
        validator.add(Self.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [
                Self.visibilityOverride(whenCanTrial: true, visible: false),
                Self.visibilityOverride(whenCanTrial: false, visible: true)
            ]
        ))

        return validator
    }

    static func context(
        customVariables: [String: CustomVariableValue] = [:],
        isEligibleForIntroOffer: @escaping (Package) -> Bool = { _ in false },
        isEligibleForPromoOffer: @escaping (Package) -> Bool = { _ in false }
    ) -> PackageSelectionContext {
        return PackageSelectionContext(
            condition: .compact,
            customVariables: customVariables,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer
        )
    }

    static func visibilityOverride(
        whenCanTrial canTrial: Bool,
        visible: Bool
    ) -> PaywallComponent.ComponentOverride<PaywallComponent.PartialPackageComponent> {
        return .init(
            extendedConditions: [
                .variable(operator: .equals, variable: "can_trial", value: .bool(canTrial))
            ],
            properties: .init(visible: visible)
        )
    }

    static func makePackageInfo(
        package: Package,
        isSelectedByDefault: Bool,
        visible: Bool?,
        overrides: [PaywallComponent.ComponentOverride<PaywallComponent.PartialPackageComponent>]? = nil
    ) -> PackageValidator.PackageInfo {
        let component = Self.makePackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            overrides: overrides
        )

        return PackageValidator.PackageInfo(
            package: package,
            isSelectedByDefault: isSelectedByDefault,
            visibilityResolver: PackageVisibilityResolver(
                component: component,
                uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
                discardRules: false
            ),
            promotionalOfferProductCode: nil
        )
    }

    static func makePackageComponent(
        packageID: String,
        isSelectedByDefault: Bool,
        visible: Bool?,
        overrides: [PaywallComponent.ComponentOverride<PaywallComponent.PartialPackageComponent>]? = nil
    ) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(
                        .init(
                            text: "package_label",
                            color: .init(light: .hex("#000000"))
                        )
                    )
                ]
            ),
            overrides: overrides
        )
    }

}

#endif
