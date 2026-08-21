//
//  PurchaseFocusRegressionUITests.swift
//  PaywallsTesterMacOSUITests
//

import XCTest

final class PurchaseFocusRegressionUITests: XCTestCase {

    private static let responsivenessPing = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.ping"
    )
    private static let responsivenessAcknowledgement = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.acknowledgement"
    )
    private static let startPurchase = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.startPurchase"
    )
    private static let purchaseStarted = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.purchaseStarted"
    )

    func testHostRemainsResponsiveWhenFocusedPaywallBecomesDisabled() {
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = [
            "-ApplePersistenceIgnoreState", "YES",
            "-NSQuitAlwaysKeepsWindows", "NO",
            "-MacOSPurchaseFocusRegression"
        ]
        app.launch()
        app.activate()

        let initialProbe = UUID().uuidString
        self.waitForAcknowledgement(
            request: Self.responsivenessPing,
            response: Self.responsivenessAcknowledgement,
            runID: initialProbe,
            retryRequest: true,
            failureMessage: "The regression scenario did not become ready."
        )

        let purchaseRunID = UUID().uuidString
        self.waitForAcknowledgement(
            request: Self.startPurchase,
            response: Self.purchaseStarted,
            runID: purchaseRunID,
            retryRequest: false,
            failureMessage: "The suspended mock purchase never entered its disabled state."
        )

        let responsivenessRunID = UUID().uuidString
        self.waitForAcknowledgement(
            request: Self.responsivenessPing,
            response: Self.responsivenessAcknowledgement,
            runID: responsivenessRunID,
            retryRequest: false,
            failureMessage: "The host stopped responding after the paywall became disabled."
        )
    }

    private func waitForAcknowledgement(
        request: Notification.Name,
        response: Notification.Name,
        runID: String,
        retryRequest: Bool,
        failureMessage: String
    ) {
        let acknowledgement = self.expectation(description: failureMessage)
        let notificationCenter = DistributedNotificationCenter.default()
        let observer = notificationCenter.addObserver(
            forName: response,
            object: runID,
            queue: .main
        ) { _ in
            acknowledgement.fulfill()
        }
        defer { notificationCenter.removeObserver(observer) }

        let attempts = retryRequest ? 10 : 1
        for attempt in 0..<attempts {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempt) * 0.5) {
                notificationCenter.postNotificationName(
                    request,
                    object: runID,
                    userInfo: nil,
                    deliverImmediately: true
                )
            }
        }
        self.wait(for: [acknowledgement], timeout: retryRequest ? 6 : 5)
    }

}
