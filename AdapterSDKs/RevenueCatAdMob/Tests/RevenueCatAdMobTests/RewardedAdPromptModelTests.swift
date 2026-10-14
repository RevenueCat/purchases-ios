import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptModelTests: AdapterTestCase {

    func testDoesNotPrepareWhenPurchasesIsNotConfigured() async {
        var results: [RewardedAdPromptUnverifiedResult] = []
        let model = self.makeModel(
            resultDispatcherFactory: {
                UnverifiedRewardResultDispatcher(onResult: { results.append($0) })
            },
            dependencies: .init(
                isPurchasesConfigured: { false },
                loadConfiguredRewards: { _ in
                    XCTFail("Configured rewards should not load")
                    return nil
                },
                trackPromptShown: { _, _ in XCTFail("An unavailable prompt must not count an impression") },
                trackPromptAccepted: { _, _ in XCTFail("An unavailable prompt must not count acceptance") }
            )
        )

        await model.prepareIfNeeded()

        XCTAssertNil(model.context)
        XCTAssertTrue(results.isEmpty)
    }

    func testResolvesRewardsForSuppliedAdOnlyOnceWithoutEnablingVerification() async throws {
        let rewards = Self.makeConfiguredRewards()
        let rewardedAd = MockRewardedAdPromptAd()
        var preparationCount = 0
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadConfiguredRewards: { adUnitID in
                XCTAssertEqual(adUnitID, rewardedAd.adUnitID)
                preparationCount += 1
                return rewards
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))

        await model.prepareIfNeeded()
        await model.prepareIfNeeded()

        XCTAssertEqual(preparationCount, 1)
        XCTAssertEqual(try XCTUnwrap(model.context).rewardConfiguration, rewards)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 0)
        XCTAssertNil(rewardedAd.delegate)
    }

    func testAllRewardMetadataStatesAllowVerifiedPresentation() async throws {
        let states: [ConfiguredAdRewards?] = [
            nil,
            ConfiguredAdRewards(),
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
                    loadConfiguredRewards: { _ in configuredRewards },
                    trackPromptShown: { _, _ in },
                    trackPromptAccepted: { _, _ in }
                )
            )

            XCTAssertNotNil(model.context)
            await model.prepareIfNeeded()
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
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.rewardVerificationResult, .verified(.noReward))
        }
    }

    func testLaterCacheReadCanResolveRewardsAndPresentSameSuppliedAd() async throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var preparationCount = 0
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadConfiguredRewards: { _ in
                preparationCount += 1
                return preparationCount == 1 ? nil : Self.makeConfiguredRewards()
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))

        await model.prepareIfNeeded()
        XCTAssertNil(model.context?.rewardConfiguration)
        XCTAssertNotNil(model.context)
        await model.prepareIfNeeded()

        XCTAssertEqual(preparationCount, 2)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)
    }

    func testCancelledCacheReadCanResumeWithoutChangingAvailability() async {
        let rewardedAd = MockRewardedAdPromptAd()
        let started = expectation(description: "Preparation started")
        var continuation: CheckedContinuation<ConfiguredAdRewards?, Never>?
        var preparationCount = 0
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadConfiguredRewards: { _ in
                preparationCount += 1
                if preparationCount == 1 {
                    return await withCheckedContinuation {
                        continuation = $0
                        started.fulfill()
                    }
                }
                return Self.makeConfiguredRewards()
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))

        let preparation = Task { await model.prepareIfNeeded() }
        await self.fulfillment(of: [started], timeout: 1)
        preparation.cancel()
        continuation?.resume(returning: Self.makeConfiguredRewards())
        await preparation.value
        XCTAssertNotNil(model.context)
        XCTAssertNil(model.context?.rewardConfiguration)

        await model.prepareIfNeeded()

        XCTAssertEqual(preparationCount, 2)
        XCTAssertNotNil(model.context)
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
                loadConfiguredRewards: { _ in Self.makeConfiguredRewards() },
                trackPromptShown: { shownEvents.append(($0, $1)) },
                trackPromptAccepted: { acceptedEvents.append(($0, $1)) }
            )
        )

        await model.prepareIfNeeded()
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
        XCTAssertTrue(rewardedAd.delegate === model)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 1)
        XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 1)
        XCTAssertEqual(rewardedAd.disableVerificationCallCount, 0)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 0)

        rewardedAd.verificationStarted?()
        rewardedAd.verificationCompleted?(.failed)

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
                loadConfiguredRewards: { _ in Self.makeConfiguredRewards() },
                trackPromptShown: { _, _ in },
                trackPromptAccepted: { _, _ in }
            )
        )

        await model.prepareIfNeeded()
        XCTAssertTrue(rewardedAd.isRewardVerificationEnabled)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()

        XCTAssertTrue(rewardedAd.delegate === model)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 1)
        XCTAssertEqual(rewardedAd.disableVerificationCallCount, 1)
        XCTAssertFalse(rewardedAd.isRewardVerificationEnabled)
        XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 0)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)

        rewardedAd.rewardEarned?()

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.kind, .rewardEarned)
    }

    func testVerifiedPresentationFailureDoesNotReturnToPreparation() async throws {
        var results: [RewardedAdPromptVerificationResult] = []
        let underlyingError = try await self.assertPresentationFailureDoesNotReturnToPreparation {
            VerifiedRewardResultDispatcher(onResult: { results.append($0) })
        }

        XCTAssertEqual(results.count, 1)
        let result = try XCTUnwrap(results.first)
        XCTAssertEqual(result.kind, .notPresented)
        XCTAssertEqual(result.presentationError?.underlyingError as NSError?, underlyingError)
        XCTAssertNil(result.rewardVerificationResult)
    }

    func testUnverifiedPresentationFailureDoesNotReturnToPreparation() async throws {
        var results: [RewardedAdPromptUnverifiedResult] = []
        let underlyingError = try await self.assertPresentationFailureDoesNotReturnToPreparation {
            UnverifiedRewardResultDispatcher(onResult: { results.append($0) })
        }

        XCTAssertEqual(results.count, 1)
        let result = try XCTUnwrap(results.first)
        XCTAssertEqual(result.kind, .notPresented)
        XCTAssertEqual(result.presentationError?.underlyingError as NSError?, underlyingError)
    }

}

@available(iOS 15.0, *)
@MainActor
extension RewardedAdPromptModelTests {

    func testPromptCanBeAcceptedWhileCachedMetadataReadIsPending() async throws {
        let rewardedAd = MockRewardedAdPromptAd()
        let started = expectation(description: "Cache read started")
        var continuation: CheckedContinuation<ConfiguredAdRewards?, Never>?
        let model = self.makeModel(ad: rewardedAd, dependencies: .init(
            isPurchasesConfigured: { true },
            loadConfiguredRewards: { _ in
                await withCheckedContinuation {
                    continuation = $0
                    started.fulfill()
                }
            },
            trackPromptShown: { _, _ in },
            trackPromptAccepted: { _, _ in }
        ))
        let preparation = Task { await model.prepareIfNeeded() }
        await self.fulfillment(of: [started], timeout: 1)

        let context = try XCTUnwrap(model.context)
        XCTAssertNil(context.rewardConfiguration)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        context.accept()

        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)
        continuation?.resume(returning: Self.makeConfiguredRewards())
        await preparation.value
        XCTAssertNil(model.context)
    }

}

@available(iOS 15.0, *)
@MainActor
private extension RewardedAdPromptModelTests {

    func assertPresentationFailureDoesNotReturnToPreparation(
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching
    ) async throws -> NSError {
        let rewardedAd = MockRewardedAdPromptAd()
        var preparationCount = 0
        let model = self.makeModel(
            ad: rewardedAd,
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadConfiguredRewards: { _ in
                    preparationCount += 1
                    return Self.makeConfiguredRewards()
                },
                trackPromptShown: { _, _ in },
                trackPromptAccepted: { _, _ in }
            )
        )

        await model.prepareIfNeeded()
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
        await model.prepareIfNeeded()

        XCTAssertTrue(model.hasAccepted)
        XCTAssertNil(model.context)
        XCTAssertEqual(preparationCount, 1)
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
        return .init(configuredReward: .unsupportedReward)
    }

}

#endif
