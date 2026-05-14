//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowContextTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowContextTests: TestCase {

    // MARK: - WorkflowContext

    func testWorkflowContextStoresPresentedOfferingContext() throws {
        let offering = TestData.offeringWithIntroOffer
        let poc = PresentedOfferingContext(offeringIdentifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: poc
        )

        expect(context.presentedOfferingContext?.offeringIdentifier) == "offering_a"
    }

    func testWorkflowContextAllowsNilPresentedOfferingContext() throws {
        let offering = TestData.offeringWithIntroOffer
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.presentedOfferingContext).to(beNil())
    }

    func testOfferingForInitialIdentifierReturnsInitialOfferingWithPresentedContext() throws {
        let presentedOfferingContext = Self.makePresentedOfferingContext()
        let initialOffering = Self.makeOffering(identifier: "offering_a")
            .withPresentedOfferingContext(presentedOfferingContext)
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([initialOffering]),
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )

        let resolvedOffering = try XCTUnwrap(context.offering(for: initialOffering.identifier))
        let packageContext = try XCTUnwrap(resolvedOffering.availablePackages.first?.presentedOfferingContext)

        expect(packageContext.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(packageContext.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(packageContext.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(packageContext.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId
    }

    func testOfferingForStepOfferingPreservesPresentedOfferingContext() throws {
        let presentedOfferingContext = Self.makePresentedOfferingContext()
        let initialOffering = Self.makeOffering(identifier: "offering_a")
            .withPresentedOfferingContext(presentedOfferingContext)
        let stepOffering = Self.makeOffering(identifier: "offering_b")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([initialOffering, stepOffering]),
            initialOffering: initialOffering,
            presentedOfferingContext: presentedOfferingContext
        )

        let resolvedOffering = try XCTUnwrap(context.offering(for: stepOffering.identifier))
        let packageContext = try XCTUnwrap(resolvedOffering.availablePackages.first?.presentedOfferingContext)

        expect(packageContext.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(packageContext.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(packageContext.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(packageContext.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId
    }

    func testOfferingForMissingIdentifierReturnsNil() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings([offering]),
            initialOffering: offering,
            presentedOfferingContext: Self.makePresentedOfferingContext()
        )

        expect(context.offering(for: "offering_missing")).to(beNil())
    }

    // MARK: - packageContext(for:)

    func testPackageContextForStepWithPackagesReturnsSelectedByDefaultPackage() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: true)
            ]
        )

        let result = context.packageContext(for: "step_terminal")

        expect(result?.selectedPackage.identifier) == "$rc_annual"
        expect(result?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_annual"]
    }

    func testPackageContextForStepWithPackagesReturnsFirstWhenNoneIsDefault() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [
                (id: "$rc_monthly", isDefault: false),
                (id: "$rc_annual", isDefault: false)
            ]
        )

        let result = context.packageContext(for: "step_terminal")

        expect(result?.selectedPackage.identifier) == "$rc_monthly"
    }

    func testPackageContextForPackagelessStepReturnsNil() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: []
        )

        expect(context.packageContext(for: "step_terminal")).to(beNil())
    }

    func testPackageContextForMissingStepReturnsNil() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)]
        )

        expect(context.packageContext(for: "step_missing")).to(beNil())
    }

    func testWorkflowPackageContextDelegatesToPackageContextForFallbackStep() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)],
            singleStepFallbackId: "step_terminal"
        )

        expect(context.workflowPackageContext?.selectedPackage.identifier) == "$rc_annual"
        expect(context.packageContext(for: "step_terminal")?.selectedPackage.identifier) == "$rc_annual"
    }

    // MARK: - effectivePackageContext(for:)

    func testEffectivePackageContextForPackageBearingStepUsesStepContextNotGlobalFallback() throws {
        // Workflow: global fallback = annual (step_fallback), step_own has monthly + weekly.
        // effectivePackageContext for step_own must return monthly — the step's own default —
        // not annual (the global fallback).
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: [(id: "$rc_monthly", isDefault: true), (id: "$rc_weekly", isDefault: false)]
        )

        let effective = context.effectivePackageContext(for: "step_own")

        expect(effective?.selectedPackage.identifier) == "$rc_monthly"
        expect(effective?.packages.map(\.identifier)) == ["$rc_monthly", "$rc_weekly"]
    }

    func testEffectivePackageContextForPackagelessStepFallsBackToGlobalWorkflowContext() throws {
        // Packageless step (step_initial) has no package components.
        // effectivePackageContext must return the global fallback (annual).
        let context = try Self.makeWorkflowContextWithFallbackAndOwnStep(
            fallbackPackages: [(id: "$rc_annual", isDefault: true)],
            ownStepPackages: []
        )

        let effective = context.effectivePackageContext(for: "step_own")

        expect(effective?.selectedPackage.identifier) == "$rc_annual"
    }

    func testEffectivePackageContextReturnsNilWhenNoPackagesAnywhere() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: []
        )

        expect(context.effectivePackageContext(for: "step_terminal")).to(beNil())
        expect(context.effectivePackageContext(for: "step_initial")).to(beNil())
    }

    func testEffectivePackageContextForFallbackStepMatchesWorkflowPackageContext() throws {
        let context = try Self.makeWorkflowContextWithPackageStep(
            stepId: "step_terminal",
            packages: [(id: "$rc_annual", isDefault: true)],
            singleStepFallbackId: "step_terminal"
        )

        let effective = context.effectivePackageContext(for: "step_terminal")

        expect(effective?.selectedPackage.identifier) == context.workflowPackageContext?.selectedPackage.identifier
    }

    // MARK: - exitOfferOfferingId

    func testExitOfferOfferingReturnsNilWhenNoSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenFallbackStepHasNoExitOffers() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithSingleStepFallback(singleStepFallbackId: "step_1"),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenExitOfferingNotInAllOfferings() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings(offering),  // exit offering not included
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilWhenSameAsCurrentOffering() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "offering_a"  // same as initial offering
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsOfferingWhenConfiguredAndAvailable() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let exitOffering = Self.makeOffering(identifier: "exit_offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings([offering, exitOffering]),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering?.identifier) == "exit_offering_a"
    }

    // MARK: - exitOfferOffering (multi-page)

    func testExitOfferOfferingReturnsNilForMultiPageWorkflowWithNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferOffering).to(beNil())
    }

    func testExitOfferOfferingReturnsNilForMultiPageWorkflowWithoutSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let exitOffering = Self.makeOffering(identifier: "exit_offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeMultiPageWorkflowWithExitOffer(
                exitOfferOfferingId: "exit_offering_a",
                onStepId: "step_2"
            ),
            allOfferings: Self.makeOfferings([offering, exitOffering]),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        // No singleStepFallbackId — exit offer is not resolved (mirrors Android's dismissExitOffer).
        expect(context.exitOfferOffering).to(beNil())
    }

    // MARK: - exitOfferTriggeringStepId

    func testExitOfferTriggeringStepIdReturnsNilWhenNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflow(),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

    func testExitOfferTriggeringStepIdReturnsNilWhenFallbackStepHasNoExitOffer() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithSingleStepFallback(singleStepFallbackId: "step_1"),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

    func testExitOfferTriggeringStepIdReturnsSingleStepFallbackIdWhenExitOfferIsConfigured() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeWorkflowWithExitOffer(
                singleStepFallbackId: "step_1",
                exitOfferOfferingId: "exit_offering_a"
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        expect(context.exitOfferTriggeringStepId) == "step_1"
    }

    func testExitOfferTriggeringStepIdReturnsNilForMultiPageWorkflowWithoutSingleStepFallbackId() throws {
        let offering = Self.makeOffering(identifier: "offering_a")
        let context = WorkflowContext(
            workflow: try Self.makeMultiPageWorkflowWithExitOffer(
                exitOfferOfferingId: "exit_offering_a",
                onStepId: "step_2"
            ),
            allOfferings: Self.makeOfferings(offering),
            initialOffering: offering,
            presentedOfferingContext: nil
        )

        // No singleStepFallbackId — triggering step is not resolved (mirrors Android's dismissExitOffer).
        expect(context.exitOfferTriggeringStepId).to(beNil())
    }

    // MARK: - resolveWorkflowContext

    func testResolveWorkflowContextThrowsWhenFlagIsOff() async throws {
        // In the unit test environment -EnableWorkflowsEndpoint is not a launch argument,
        // so workflowsEndpointEnabled returns false and resolveWorkflowContext must throw.
        let handler: PurchaseHandler = .mock()

        await expect {
            try await handler.resolveWorkflowContext(
                identifier: "offering_a",
                presentedOfferingContext: nil
            )
        }.to(throwError(PaywallError.offeringNotFound(identifier: "offering_a")))
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowContextTests {

    static func makeOfferings(_ offering: Offering) -> Offerings {
        return self.makeOfferings([offering])
    }

    static func makeOfferings(_ offerings: [Offering]) -> Offerings {
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )
    }

    static func makeOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: TestData.paywallWithIntroOffer,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

    static func makePresentedOfferingContext() -> PresentedOfferingContext {
        return .init(
            offeringIdentifier: "offering_a",
            placementIdentifier: "home_screen",
            targetingContext: .init(revision: 7, ruleId: "rule_1")
        )
    }

    typealias PackageSpec = (id: String, isDefault: Bool)

    /// Builds a `WorkflowContext` containing one step with package components,
    /// backed by an offering that has all the named packages.
    /// Builds a `WorkflowContext` with two package-bearing steps:
    /// - `step_fallback` (set as `singleStepFallbackId`) with `fallbackPackages`
    /// - `step_own` with `ownStepPackages` (may be empty to simulate a packageless step)
    static func makeWorkflowContextWithFallbackAndOwnStep(
        fallbackPackages: [PackageSpec],
        ownStepPackages: [PackageSpec]
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let allPackages = (fallbackPackages + ownStepPackages)
            .map { spec in
                Package(
                    identifier: spec.id,
                    packageType: .custom,
                    storeProduct: TestData.monthlyPackage.storeProduct,
                    offeringIdentifier: offeringId,
                    webCheckoutUrl: nil
                )
            }
        let offering = Offering(
            identifier: offeringId,
            serverDescription: "Test",
            metadata: [:],
            paywall: nil,
            availablePackages: allPackages,
            webCheckoutUrl: nil
        )
        let offerings = Offerings(
            offerings: [offeringId: offering],
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )

        func screenJSON(packages: [PackageSpec]) -> String {
            let componentsJSON = packages.map { pkg in
                """
                {
                    "type": "package",
                    "packageId": "\(pkg.id)",
                    "isSelectedByDefault": \(pkg.isDefault),
                    "stack": \(Self.minimalStackJSON())
                }
                """
            }.joined(separator: ",")
            return """
            {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "offering_identifier": "\(offeringId)",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": \(Self.minimalStackJSON(components: "[\(componentsJSON)]")),
                  "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
                }
              }
            }
            """
        }

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          "single_step_fallback_id": "step_fallback",
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen" },
            "step_fallback": { "id": "step_fallback", "type": "screen", "screen_id": "screen_fallback" },
            "step_own": { "id": "step_own", "type": "screen", "screen_id": "screen_own" }
          },
          "screens": {
            "screen_fallback": \(screenJSON(packages: fallbackPackages)),
            "screen_own": \(screenJSON(packages: ownStepPackages))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        return WorkflowContext(
            workflow: workflow,
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

    static func makeWorkflowContextWithPackageStep(
        stepId: String,
        packages: [PackageSpec],
        singleStepFallbackId: String? = nil
    ) throws -> WorkflowContext {
        let offeringId = "offering_test"
        let fallbackJSON = singleStepFallbackId.map { "\"single_step_fallback_id\": \"\($0)\"," } ?? ""
        let componentsJSON = packages
            .map { pkg in
                """
                {
                    "type": "package",
                    "packageId": "\(pkg.id)",
                    "isSelectedByDefault": \(pkg.isDefault),
                    "stack": \(Self.minimalStackJSON())
                }
                """
            }
            .joined(separator: ",")

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_initial",
          \(fallbackJSON)
          "steps": {
            "step_initial": { "id": "step_initial", "type": "screen" },
            "\(stepId)": { "id": "\(stepId)", "type": "screen", "screen_id": "screen_target" }
          },
          "screens": {
            "screen_target": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "offering_identifier": "\(offeringId)",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": \(Self.minimalStackJSON(components: "[\(componentsJSON)]")),
                  "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
                }
              }
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )

        let rcPackages = packages.map { spec in
            Package(
                identifier: spec.id,
                packageType: .custom,
                storeProduct: TestData.monthlyPackage.storeProduct,
                offeringIdentifier: offeringId,
                webCheckoutUrl: nil
            )
        }
        let offering = Offering(
            identifier: offeringId,
            serverDescription: "Test",
            metadata: [:],
            paywall: nil,
            availablePackages: rcPackages,
            webCheckoutUrl: nil
        )
        let offerings = Offerings(
            offerings: [offeringId: offering],
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: nil,
                    offerings: [],
                    placements: nil,
                    targeting: nil,
                    uiConfig: nil
                ),
                httpResponseOriginalSource: .mainServer
            ),
            loadedFromDiskCache: false
        )
        return WorkflowContext(
            workflow: workflow,
            allOfferings: offerings,
            initialOffering: offering,
            presentedOfferingContext: nil
        )
    }

    static func minimalStackJSON(components: String = "[]") -> String {
        return """
        {
          "type": "stack", "components": \(components),
          "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
          "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
          "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
          "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
        }
        """
    }

    static func makeWorkflow() throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen" }
          },
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func makeWorkflowWithSingleStepFallback(singleStepFallbackId: String) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "single_step_fallback_id": "\(singleStepFallbackId)",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON())
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func makeWorkflowWithExitOffer(
        singleStepFallbackId: String,
        exitOfferOfferingId: String
    ) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "single_step_fallback_id": "\(singleStepFallbackId)",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON(exitOfferOfferingId: exitOfferOfferingId))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func makeMultiPageWorkflowWithExitOffer(
        exitOfferOfferingId: String,
        onStepId: String
    ) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" },
            "\(onStepId)": { "id": "\(onStepId)", "type": "screen", "screen_id": "screen_2" }
          },
          "screens": {
            "screen_1": \(Self.screenJSON()),
            "screen_2": \(Self.screenJSON(exitOfferOfferingId: exitOfferOfferingId))
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func screenJSON(exitOfferOfferingId: String? = nil) -> String {
        let exitOffersJSON = exitOfferOfferingId.map {
            #", "exit_offers": { "dismiss": { "offering_id": "\#($0)" } }"#
        } ?? ""
        return """
        {
          "template_name": "tmpl",
          "asset_base_url": "https://assets.revenuecat.com",
          "default_locale": "en_US",
          "components_localizations": {},
          "components_config": {
            "base": {
              "stack": {
                "type": "stack", "components": [],
                "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
              },
              "background": { "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } } }
            }
          }\(exitOffersJSON)
        }
        """
    }

}

#endif
