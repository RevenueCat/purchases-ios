// Copyright RevenueCat Inc. All Rights Reserved.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class SheetOnlyPackageSelectionTests: TestCase {

    func testSheetOnlyProvisionalSelectionReconcilesUsingRealVariables() {
        let factory = ViewModelFactory()
        PackageValidatorTests.canTrialValidator().packageInfos.forEach { factory.sheetPackageValidator.add($0) }
        let seeded = PaywallsV2View.defaultSelectedPackage(
            in: factory,
            context: .provisional,
            workflowDefaultPackage: nil
        )
        let realContext = PackageValidatorTests.context(customVariables: ["can_trial": .bool(false)])

        XCTAssertEqual(seeded?.identifier, TestData.annualPackage.identifier)
        XCTAssertEqual(
            PaywallsV2View.defaultSelectedPackage(
                in: factory,
                context: realContext,
                workflowDefaultPackage: nil
            )?.identifier,
            TestData.monthlyPackage.identifier
        )
        XCTAssertFalse(factory.sheetPackageValidator.couldBeRendering(
            TestData.annualPackage,
            in: realContext,
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        ))
        XCTAssertEqual(factory.rootSelectionValidator.reconciledSelection(
            current: seeded,
            in: realContext,
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        )?.identifier, TestData.monthlyPackage.identifier)
    }

    func testClosedSheetReconciliationSelectsAPackageThatBecomesAvailableWithRealVariables() {
        let factory = ViewModelFactory()
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            visible: false,
            overrides: [PackageValidatorTests.visibilityOverride(whenCanTrial: false, visible: true)]
        ))
        XCTAssertNil(factory.rootSelectionValidator.defaultSelectedPackage(in: .provisional))

        XCTAssertEqual(factory.rootSelectionValidator.reconciledSelection(
            current: nil,
            in: PackageValidatorTests.context(customVariables: ["can_trial": .bool(false)]),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        )?.identifier, TestData.monthlyPackage.identifier)
    }

    func testClosedSheetSelectionReconcilesOnResizeAndKeepsTheReplacementWhenItRemainsValid() {
        let factory = ViewModelFactory()
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                properties: .init(visible: false)
            )]
        ))
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true
        ))

        let replacement = factory.rootSelectionValidator.reconciledSelection(
            current: TestData.annualPackage,
            in: PackageValidatorTests.context(windowSize: CGSize(width: 800, height: 600)),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        )
        XCTAssertEqual(replacement?.identifier, TestData.monthlyPackage.identifier)
        XCTAssertNil(factory.rootSelectionValidator.reconciledSelection(
            current: replacement,
            in: PackageValidatorTests.context(windowSize: CGSize(width: 400, height: 800)),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        ))
    }

    func testClosedSheetSelectionWaitsForEligibilityThenReconciles() {
        let factory = ViewModelFactory()
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true,
            overrides: [PackageValidatorTests.offerVisibilityOverride(.introOffer, visible: false)]
        ))
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true
        ))
        let context = PackageValidatorTests.context(isEligibleForIntroOffer: { _ in true })
        XCTAssertNil(factory.rootSelectionValidator.reconciledSelection(
            current: TestData.annualPackage,
            in: context,
            offerEligibilityLoading: [.intro],
            offerEligibilityAvailability: .unknown
        ))
        XCTAssertEqual(factory.rootSelectionValidator.reconciledSelection(
            current: TestData.annualPackage,
            in: context,
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        )?.identifier, TestData.monthlyPackage.identifier)
    }

    func testClosedSheetReconciliationPreservesAManualChoiceHiddenBySelection() {
        let factory = ViewModelFactory()
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: true
        ))
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            visible: true,
            overrides: [.init(extendedConditions: [.selected], properties: .init(visible: false))]
        ))

        XCTAssertNil(factory.rootSelectionValidator.reconciledSelection(
            current: TestData.monthlyPackage,
            in: PackageValidatorTests.context(),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        ))
    }

    func testClosedSheetReconciliationRetainsTheSelectionWhenNoReplacementIsVisible() {
        let factory = ViewModelFactory()
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: false
        ))

        XCTAssertNil(factory.rootSelectionValidator.reconciledSelection(
            current: TestData.annualPackage,
            in: PackageValidatorTests.context(),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        ))
    }

    func testPagePackagesKeepPrecedenceOverClosedSheetPackagesDuringReconciliation() {
        let factory = ViewModelFactory()
        factory.packageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.annualPackage,
            isSelectedByDefault: true,
            visible: false
        ))
        factory.sheetPackageValidator.add(PackageValidatorTests.makePackageInfo(
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            visible: true
        ))

        XCTAssertNil(factory.rootSelectionValidator.reconciledSelection(
            current: TestData.annualPackage,
            in: PackageValidatorTests.context(),
            offerEligibilityLoading: [],
            offerEligibilityAvailability: .unknown
        ))
    }

}

#endif
