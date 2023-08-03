//
//  BaseSnapshotTest.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//
import Nimble
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class BaseSnapshotTest: TestCase {

    override class func setUp() {
        super.setUp()

        // isRecording = true
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension BaseSnapshotTest {

    static let eligibleChecker: TrialOrIntroEligibilityChecker = .producing(eligibility: .eligible)
    static let ineligibleChecker: TrialOrIntroEligibilityChecker = .producing(eligibility: .ineligible)
    static let purchaseHandler: PurchaseHandler = .mock()

    static let fullScreenSize: CGSize = .init(width: 460, height: 950)

    // Disabled until we bring modes back.
    /*
    static let cardSize: CGSize = .init(width: 460, height: 460)
    static let bannerSize: CGSize = .init(width: 380, height: 70)
    */

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// Adds the receiver to a view hierarchy to be able to test lifetime logic.
    func addToHierarchy() {
        let controller = UIHostingController(
            rootView: self
                .frame(width: BaseSnapshotTest.fullScreenSize.width,
                       height: BaseSnapshotTest.fullScreenSize.height)
        )

        let window = UIWindow()
        window.rootViewController = controller
        window.frame.size = BaseSnapshotTest.fullScreenSize
        window.setNeedsLayout()
        window.layoutIfNeeded()

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
    }

}
