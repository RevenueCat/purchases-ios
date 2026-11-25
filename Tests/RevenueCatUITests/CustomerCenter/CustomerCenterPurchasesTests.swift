//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPurchasesTests.swift
//
//  Created by Rick van der Linden on 11/18/26.

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPurchasesTests: TestCase {

    func testPackagePurchaseUsesPresentationContext() async throws {
        let capturedParams: Atomic<PurchaseParams?> = nil
        let purchases = CustomerCenterPurchases { params in
            capturedParams.value = params
            return (nil, TestData.customerInfo, false)
        }
        let owner = NSObject()
        let (window, scene) = try self.makeWindowAndScene()
        purchases.updatePresentationWindow(window, reportedBy: owner)

        let package = TestData.packageWithIntroOffer
        _ = try await purchases.purchase(package: package)

        let params = try XCTUnwrap(capturedParams.value)
        XCTAssertTrue(params.package === package)
        XCTAssertTrue(params.presentationContext?.window === window)
        XCTAssertTrue(params.presentationContext?.scene === scene)
        XCTAssertTrue(params.presentationContext?.allowsDefaultPresentationFallback == true)
    }

    func testProductPurchasePreservesPromotionalOfferAndUsesPresentationContext() async throws {
        let capturedParams: Atomic<PurchaseParams?> = nil
        let purchases = self.makePurchases(capturedParams: capturedParams)
        let owner = NSObject()
        let (window, scene) = try self.makeWindowAndScene()
        purchases.updatePresentationWindow(window, reportedBy: owner)

        let product = TestData.packageWithIntroOffer.storeProduct
        let offer = self.makePromotionalOffer()
        _ = try await purchases.purchase(product: product, promotionalOffer: offer)

        let params = try XCTUnwrap(capturedParams.value)
        XCTAssertEqual(params.product?.productIdentifier, product.productIdentifier)
        XCTAssertTrue(params.promotionalOffer === offer)
        XCTAssertTrue(params.presentationContext?.window === window)
        XCTAssertTrue(params.presentationContext?.scene === scene)
    }

    func testStaleOwnerCannotClearNewPresentationWindow() async throws {
        let capturedParams: Atomic<PurchaseParams?> = nil
        let purchases = self.makePurchases(capturedParams: capturedParams)
        let firstOwner = NSObject()
        let secondOwner = NSObject()
        let (firstWindow, _) = try self.makeWindowAndScene()
        let (secondWindow, _) = try self.makeWindowAndScene()
        purchases.updatePresentationWindow(firstWindow, reportedBy: firstOwner)
        purchases.updatePresentationWindow(secondWindow, reportedBy: secondOwner)

        purchases.updatePresentationWindow(nil, reportedBy: firstOwner)
        _ = try await purchases.purchase(package: TestData.packageWithIntroOffer)

        XCTAssertTrue(capturedParams.value?.presentationContext?.window === secondWindow)
    }

    private func makePurchases(
        capturedParams: Atomic<PurchaseParams?>
    ) -> CustomerCenterPurchases {
        return CustomerCenterPurchases { params in
            capturedParams.value = params
            return (nil, TestData.customerInfo, false)
        }
    }

    private func makeWindowAndScene() throws -> (UIWindow, UIWindowScene) {
        let sceneClass = try XCTUnwrap(NSClassFromString("UIWindowScene") as? NSObject.Type)
        let scene = try XCTUnwrap(sceneClass.init() as? UIWindowScene)
        let window = CustomerCenterMockPresentationWindow()
        window.presentationScene = scene
        return (window, scene)
    }

    private func makePromotionalOffer() -> PromotionalOffer {
        let signedData = PromotionalOffer.SignedData(
            identifier: "offer",
            keyIdentifier: "key",
            nonce: UUID(),
            signature: "signature",
            timestamp: 1234
        )
        let discount = MockStoreProductDiscount(
            offerIdentifier: "offer",
            currencyCode: "usd",
            price: 1,
            localizedPriceString: "$1.00",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .promotional
        )
        return PromotionalOffer(discount: discount, signedData: signedData)
    }

}

@available(iOS 15.0, *)
@MainActor
private final class CustomerCenterMockPresentationWindow: UIWindow {

    var presentationScene: UIWindowScene?

    override var windowScene: UIWindowScene? {
        get { self.presentationScene }
        set { self.presentationScene = newValue }
    }

}
#endif
