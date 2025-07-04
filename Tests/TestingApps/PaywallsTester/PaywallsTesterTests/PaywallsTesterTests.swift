//
//  PaywallsTesterTests.swift
//  PaywallsTesterTests
//
//  Created by Noah Martin on 10/24/24.
//

import XCTest
import SnapshottingTests

final class PaywallsTesterTests: SnapshotTest {
    override class func snapshotPreviews() -> [String]? {
        // Gets around an issue that was causing StoreKit previews to be included when running in Catalyst mode.
        // Should be fixed in EmergeTools v0.10.23+, and this won't be necessary anymore.
        // PR: https://github.com/EmergeTools/SnapshotPreviews/pull/239
        return ["PaywallsTester.*", "RevenueCatUI.*"]
    }
}
