//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallOfferingIdentifierOwnershipTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

/// Hybrid SDKs hand `PaywallViewController` an offering identifier as an `NSString` they own. Bridging an
/// immutable `NSString` doesn't copy it: the resulting `String` messages the caller's object every time it
/// is hashed or compared. The paywall does that after `await purchases.offerings()`, often on a background
/// thread, by which point the caller may no longer hold the string.
/// See https://github.com/RevenueCat/react-native-purchases/issues/2018.
///
/// These tests go through the same Objective-C entry points the hybrids use and check that RevenueCatUI
/// stops touching the caller's string as soon as the call returns.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@MainActor
final class PaywallOfferingIdentifierOwnershipTests: TestCase {

    func testUpdateWithOfferingIdentifierDoesNotReadCallerStringAfterReturning() async throws {
        let offering = Self.createOffering()
        let callerString = CallerOwnedNSString(offering.identifier)
        let controller = PaywallViewController(offering: nil)

        _ = controller.perform(
            NSSelectorFromString("updateWithOfferingIdentifier:presentedOfferingContext:"),
            with: callerString,
            with: nil
        )
        callerString.callerReleasedIt()

        let resolved = try await Self.resolveAfterSuspending(controller.contentForTesting, offerings: [offering])

        expect(resolved.identifier) == offering.identifier
        expect(callerString.readsAfterCallerReleasedIt) == 0
    }

    func testDeprecatedUpdateWithOfferingIdentifierDoesNotReadCallerStringAfterReturning() async throws {
        let offering = Self.createOffering()
        let callerString = CallerOwnedNSString(offering.identifier)
        let controller = PaywallViewController(offering: nil)

        _ = controller.perform(NSSelectorFromString("updateWithOfferingIdentifier:"), with: callerString)
        callerString.callerReleasedIt()

        let resolved = try await Self.resolveAfterSuspending(controller.contentForTesting, offerings: [offering])

        expect(resolved.identifier) == offering.identifier
        expect(callerString.readsAfterCallerReleasedIt) == 0
    }

    func testInitWithOfferingIdentifierDoesNotReadCallerStringAfterReturning() async throws {
        let offering = Self.createOffering()
        let callerString = CallerOwnedNSString(offering.identifier)
        let presentedOfferingContext = PresentedOfferingContext(offeringIdentifier: offering.identifier)

        let controller = PaywallViewController(
            offeringIdentifier: callerString as String,
            presentedOfferingContext: presentedOfferingContext
        )
        callerString.callerReleasedIt()

        let resolved = try await Self.resolveAfterSuspending(controller.contentForTesting, offerings: [offering])

        expect(resolved.identifier) == offering.identifier
        expect(resolved.presentedOfferingContext) === presentedOfferingContext
        expect(callerString.readsAfterCallerReleasedIt) == 0
    }

    func testCachedOfferingLookupDoesNotReadCallerStringAfterUpdateReturns() throws {
        let offering = Self.createOffering()
        let callerString = CallerOwnedNSString(offering.identifier)
        let controller = PaywallViewController(offering: nil)

        _ = controller.perform(
            NSSelectorFromString("updateWithOfferingIdentifier:presentedOfferingContext:"),
            with: callerString,
            with: nil
        )
        callerString.callerReleasedIt()

        let purchases = Self.createMockPurchases()
        purchases.cachedOfferings = Self.createOfferings([offering])
        let handler = PurchaseHandler(purchases: purchases, eventTracker: .init(purchases: purchases))

        let cached = handler.cachedInitialOffering(for: controller.contentForTesting, remoteConfigEnabled: false)

        expect(cached?.identifier) == offering.identifier
        expect(callerString.readsAfterCallerReleasedIt) == 0
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallOfferingIdentifierOwnershipTests {

    /// Resolves `content` the way `PaywallView` does, with the offerings fetch suspending for real so the
    /// identifier lookup runs on resumption, as it does in production.
    static func resolveAfterSuspending(
        _ content: PaywallViewConfiguration.Content,
        offerings: [Offering]
    ) async throws -> Offering {
        let purchases = Self.createMockPurchases()
        purchases.offeringsBlock = {
            await Task.yield()
            return Self.createOfferings(offerings)
        }
        let handler = PurchaseHandler(purchases: purchases, eventTracker: .init(purchases: purchases))

        return try await handler.resolveOfferingOrThrow(for: content)
    }

    static func createMockPurchases() -> MockPurchases {
        return MockPurchases { _, _, _ in
            (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            TestData.customerInfo
        }
    }

    static func createOfferings(_ offerings: [Offering]) -> Offerings {
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: offerings.first?.identifier,
            placements: nil,
            targeting: nil,
            contents: .init(
                response: .init(
                    currentOfferingId: offerings.first?.identifier,
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

    /// Long enough that Foundation can't hand Swift a tagged pointer, which would be copied eagerly.
    static func createOffering(identifier: String = "offering_identifier_owned_by_the_hybrid_caller") -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: TestData.paywallWithIntroOffer,
            availablePackages: TestData.packages,
            webCheckoutUrl: nil
        )
    }

}

/// An immutable `NSString` standing in for the one a hybrid SDK passes in.
///
/// Like `__NSCFString`, `copy` returns `self`, so Swift's bridged `String` keeps pointing at this object
/// rather than at a copy. Every read that happens after the caller stops holding it is counted: in
/// production that read lands on a released object and crashes in `String.hash(into:)`.
private final class CallerOwnedNSString: NSString {

    private var storage: [unichar] = []
    private let released: Atomic<Bool> = .init(false)
    private let readsAfterRelease: Atomic<Int> = .init(0)

    convenience init(_ value: String) {
        self.init()
        self.storage = Array(value.utf16)
    }

    /// Marks the point after which the caller no longer guarantees this object is alive.
    func callerReleasedIt() {
        self.released.value = true
    }

    var readsAfterCallerReleasedIt: Int {
        return self.readsAfterRelease.value
    }

    override var length: Int {
        self.recordRead()
        return self.storage.count
    }

    override func character(at index: Int) -> unichar {
        self.recordRead()
        return self.storage[index]
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    private func recordRead() {
        guard self.released.value else { return }
        self.readsAfterRelease.modify { $0 += 1 }
    }

}

#endif
