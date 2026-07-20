//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExitOfferPresenterTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class ExitOfferPresenterTests: TestCase {

    private let offering = TestData.offeringWithNoIntroOffer

    func testWorkflowPreferenceSetsOfferWhenRemoteConfigEnabled() {
        let presenter = ExitOfferPresenter(purchaseHandler: .mock(remoteConfigEnabled: true))

        presenter.updateFromWorkflowPreference(.init(exitOfferOffering: self.offering))

        expect(presenter.workflowBinding.wrappedValue?.identifier) == self.offering.identifier
        expect(presenter.presentIfAvailable()) == true
        expect(presenter.isPresentingExitOffer) == true
    }

    func testWorkflowPreferenceIgnoredWhenRemoteConfigDisabled() {
        let presenter = ExitOfferPresenter(purchaseHandler: .mock(remoteConfigEnabled: false))

        presenter.updateFromWorkflowPreference(.init(exitOfferOffering: self.offering))

        expect(presenter.workflowBinding.wrappedValue).to(beNil())
        expect(presenter.presentIfAvailable()) == false
        expect(presenter.isPresentingExitOffer) == false
    }

    func testNilPreferenceDoesNotClearAlreadyPresentedOffer() {
        let presenter = ExitOfferPresenter(purchaseHandler: .mock(remoteConfigEnabled: true))

        presenter.updateFromWorkflowPreference(.init(exitOfferOffering: self.offering))
        expect(presenter.presentIfAvailable()) == true

        // A late nil preference (fired during the dismiss animation) must not clear the offer being shown.
        presenter.updateFromWorkflowPreference(nil)

        expect(presenter.isPresentingExitOffer) == true
        expect(presenter.workflowBinding.wrappedValue?.identifier) == self.offering.identifier
    }

    func testNilPreferenceClearsOfferWhenNotPresenting() {
        let presenter = ExitOfferPresenter(purchaseHandler: .mock(remoteConfigEnabled: true))

        presenter.updateFromWorkflowPreference(.init(exitOfferOffering: self.offering))
        presenter.updateFromWorkflowPreference(nil)

        expect(presenter.workflowBinding.wrappedValue).to(beNil())
        expect(presenter.presentIfAvailable()) == false
    }

    func testLegacyPrefetchSkippedWhenRemoteConfigEnabled() async {
        let presenter = ExitOfferPresenter(purchaseHandler: .mock(remoteConfigEnabled: true))
        var resolveOfferingCalled = false

        await presenter.prefetchLegacyExitOffer {
            resolveOfferingCalled = true
            return self.offering
        }

        // Under workflows the exit offer comes from the step-aware preference, so the offering-level
        // prefetch must not run (this is the gap that surfaced the exit offer on non-exit-offer steps).
        expect(resolveOfferingCalled) == false
        expect(presenter.workflowBinding.wrappedValue).to(beNil())
    }

}

#endif
