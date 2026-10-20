import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptModelTests: AdapterTestCase {

    func testDoesNotLoadRewardsWhenPurchasesIsNotConfigured() async {
        var results: [RewardedAdPromptUnverifiedResult] = []
        let model = self.makeModel(
            resultDispatcherFactory: {
                UnverifiedRewardResultDispatcher(onResult: { results.append($0) })
            },
            dependencies: .init(
                isPurchasesConfigured: { false },
                loadRewards: { _ in
                    XCTFail("Configured rewards should not load")
                    return nil
                },
                trackPromptShown: { _, _ in XCTFail("An unavailable prompt must not count an impression") },
                trackPromptAccepted: { _, _ in XCTFail("An unavailable prompt must not count acceptance") }
            )
        )

        await model.loadRewardsIfNeeded()

        XCTAssertNil(model.context)
        XCTAssertTrue(results.isEmpty)
    }

    func testLoadingRewardsUpdatesContextWithoutEnablingVerification() async throws {
        let rewards = Self.makeConfiguredRewards()
        let rewardedAd = MockRewardedAdPromptAd()
        var rewardsLoadCount = 0
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadRewards: { adUnitID in
                XCTAssertEqual(adUnitID, rewardedAd.adUnitID)
                rewardsLoadCount += 1
                return rewards
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))

        XCTAssertNil(try XCTUnwrap(model.context).rewardConfiguration)
        await model.loadRewardsIfNeeded()
        XCTAssertEqual(try XCTUnwrap(model.context).rewardConfiguration, rewards)
        XCTAssertEqual(rewardsLoadCount, 1)
        await model.loadRewardsIfNeeded()
        XCTAssertEqual(rewardsLoadCount, 1)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 0)
        XCTAssertNil(rewardedAd.delegate)
    }

    func testAllRewardMetadataStatesAllowVerifiedPresentation() async throws {
        let states: [ConfiguredAdRewards?] = [
            nil,
            ConfiguredAdRewards.noConfiguredReward,
            Self.makeConfiguredRewards()
        ]
        for configuredRewards in states {
            let rewardedAd = MockRewardedAdPromptAd()
            var results: [RewardedAdPromptVerificationResult] = []
            let model = self.makeModel(
                ad: rewardedAd,
                resultDispatcherFactory: {
                    VerifiedRewardResultDispatcher(onResult: { results.append($0) })
                },
                dependencies: .init(
                    isPurchasesConfigured: { true },
                    loadRewards: { _ in configuredRewards },
                    trackPromptShown: { _, _ in },
                    trackPromptAccepted: { _, _ in }
                )
            )

            XCTAssertNotNil(model.context)
            await model.loadRewardsIfNeeded()
            let context = try XCTUnwrap(model.context)
            XCTAssertEqual(context.rewardConfiguration, configuredRewards)
            XCTAssertTrue(results.isEmpty)
            let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
            defer { window.isHidden = true }
            model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
            context.accept()

            XCTAssertEqual(rewardedAd.enableVerificationCallCount, 1)
            XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 1)
            rewardedAd.verificationStarted?()
            rewardedAd.verificationCompleted?(.verified(.noReward))
            XCTAssertTrue(results.isEmpty)
            rewardedAd.delegate?.adDidDismissFullScreenContent?(PresentedAdStub())
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.rewardVerificationResult, .verified(.noReward))
        }
    }

    func testLaterLoadCanResolveRewardsAndPresentSameSuppliedAd() async throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var rewardsLoadCount = 0
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadRewards: { _ in
                rewardsLoadCount += 1
                return rewardsLoadCount == 1 ? nil : Self.makeConfiguredRewards()
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))

        XCTAssertNil(model.context?.rewardConfiguration)
        XCTAssertNotNil(model.context)
        await model.loadRewardsIfNeeded()
        XCTAssertNil(model.context?.rewardConfiguration)
        await model.loadRewardsIfNeeded()

        XCTAssertEqual(rewardsLoadCount, 2)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)
    }

    func testTracksShownAndAcceptedOnceAndPresentsVerificationEnabledAd() async throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var shownEvents: [(String, String?)] = []
        var acceptedEvents: [(String, String?)] = []
        var results: [RewardedAdPromptVerificationResult] = []
        let model = self.makeModel(
            ad: rewardedAd,
            resultDispatcherFactory: {
                VerifiedRewardResultDispatcher(onResult: { results.append($0) })
            },
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadRewards: { _ in Self.makeConfiguredRewards() },
                trackPromptShown: { shownEvents.append(($0, $1)) },
                trackPromptAccepted: { acceptedEvents.append(($0, $1)) }
            )
        )

        await model.loadRewardsIfNeeded()
        model.promptDidAppear()
        model.promptDidAppear()
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        let context = try XCTUnwrap(model.context)

        context.accept()
        context.accept()

        XCTAssertEqual(shownEvents.count, 1)
        XCTAssertEqual(shownEvents.first?.0, rewardedAd.adUnitID)
        XCTAssertEqual(shownEvents.first?.1, "placement")
        XCTAssertEqual(acceptedEvents.count, 1)
        XCTAssertEqual(acceptedEvents.first?.0, rewardedAd.adUnitID)
        XCTAssertEqual(acceptedEvents.first?.1, "placement")
        XCTAssertTrue(model.hasAccepted)
        XCTAssertNil(model.context)
        XCTAssertNotNil(rewardedAd.delegate)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 1)
        XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 1)
        XCTAssertEqual(rewardedAd.disableVerificationCallCount, 0)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 0)

        rewardedAd.verificationStarted?()
        rewardedAd.verificationCompleted?(.failed)

        XCTAssertTrue(results.isEmpty)
        rewardedAd.delegate?.adDidDismissFullScreenContent?(PresentedAdStub())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.kind, .verificationCompleted)
    }

    func testVerificationDisabledResultOverridesPreviouslyEnabledVerification() async throws {
        let rewardedAd = MockRewardedAdPromptAd()
        rewardedAd.enableRewardVerification()
        var results: [RewardedAdPromptUnverifiedResult] = []
        let model = self.makeModel(
            ad: rewardedAd,
            resultDispatcherFactory: {
                UnverifiedRewardResultDispatcher(onResult: { results.append($0) })
            },
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadRewards: { _ in Self.makeConfiguredRewards() },
                trackPromptShown: { _, _ in },
                trackPromptAccepted: { _, _ in }
            )
        )

        await model.loadRewardsIfNeeded()
        XCTAssertTrue(rewardedAd.isRewardVerificationEnabled)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()

        XCTAssertNotNil(rewardedAd.delegate)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 1)
        XCTAssertEqual(rewardedAd.disableVerificationCallCount, 1)
        XCTAssertFalse(rewardedAd.isRewardVerificationEnabled)
        XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 0)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)

        rewardedAd.rewardEarned?()

        XCTAssertTrue(results.isEmpty)
        rewardedAd.delegate?.adDidDismissFullScreenContent?(PresentedAdStub())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.kind, .rewardEarned)
    }

    func testVerifiedPresentationFailureDoesNotLoadRewardsAgain() async throws {
        let delivered = self.expectation(description: "Presentation failure delivered")
        var results: [RewardedAdPromptVerificationResult] = []
        let underlyingError = try await self.assertPresentationFailureDoesNotLoadRewardsAgain {
            VerifiedRewardResultDispatcher(onResult: {
                results.append($0)
                delivered.fulfill()
            })
        }

        XCTAssertTrue(results.isEmpty)
        await self.fulfillment(of: [delivered], timeout: 1)

        XCTAssertEqual(results.count, 1)
        let result = try XCTUnwrap(results.first)
        XCTAssertEqual(result.kind, .notPresented)
        XCTAssertEqual(result.presentationError?.underlyingError as NSError?, underlyingError)
        XCTAssertNil(result.rewardVerificationResult)
    }

    func testUnverifiedPresentationFailureDoesNotLoadRewardsAgain() async throws {
        let delivered = self.expectation(description: "Presentation failure delivered")
        var results: [RewardedAdPromptUnverifiedResult] = []
        let underlyingError = try await self.assertPresentationFailureDoesNotLoadRewardsAgain {
            UnverifiedRewardResultDispatcher(onResult: {
                results.append($0)
                delivered.fulfill()
            })
        }

        XCTAssertTrue(results.isEmpty)
        await self.fulfillment(of: [delivered], timeout: 1)

        XCTAssertEqual(results.count, 1)
        let result = try XCTUnwrap(results.first)
        XCTAssertEqual(result.kind, .notPresented)
        XCTAssertEqual(result.presentationError?.underlyingError as NSError?, underlyingError)
    }

}

@available(iOS 15.0, *)
@MainActor
private extension RewardedAdPromptModelTests {

    func assertPresentationFailureDoesNotLoadRewardsAgain(
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching
    ) async throws -> NSError {
        let rewardedAd = MockRewardedAdPromptAd()
        var rewardsLoadCount = 0
        let model = self.makeModel(
            ad: rewardedAd,
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadRewards: { _ in
                    rewardsLoadCount += 1
                    return Self.makeConfiguredRewards()
                },
                trackPromptShown: { _, _ in },
                trackPromptAccepted: { _, _ in }
            )
        )

        await model.loadRewardsIfNeeded()
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        let context = try XCTUnwrap(model.context)
        context.accept()

        let underlyingError = NSError(domain: "test.presentation", code: 1)
        let presentingAd = PresentedAdStub()
        rewardedAd.delegate?.ad?(presentingAd, didFailToPresentFullScreenContentWithError: underlyingError)
        rewardedAd.delegate?.ad?(presentingAd, didFailToPresentFullScreenContentWithError: underlyingError)
        rewardedAd.delegate?.adDidDismissFullScreenContent?(presentingAd)
        rewardedAd.rewardEarned?()
        rewardedAd.verificationCompleted?(.failed)
        context.accept()
        await model.loadRewardsIfNeeded()

        XCTAssertTrue(model.hasAccepted)
        XCTAssertNil(model.context)
        XCTAssertEqual(rewardsLoadCount, 1)
        XCTAssertEqual(
            rewardedAd.verificationEnabledPresentationCount + rewardedAd.verificationDisabledPresentationCount,
            1
        )
        return underlyingError
    }

    func makeModel(
        ad rewardedAd: MockRewardedAdPromptAd? = nil,
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching = {
            UnverifiedRewardResultDispatcher(onResult: { _ in })
        },
        dependencies: RewardedAdPromptDependencies
    ) -> RewardedAdPromptModel {
        return .init(
            session: RewardedAdPromptSession(),
            ad: rewardedAd ?? MockRewardedAdPromptAd(),
            placement: "placement",
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: dependencies
        )
    }

    static func makeConfiguredRewards() -> ConfiguredAdRewards {
        return .init(reward: .unsupportedReward, moreRewards: [])
    }

}

#endif
