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
        // This method only applies when running these tests locally. When running on EmergeTools' server,
        // we apply the same exclusion by specifying it in emerge_config.yaml.
        // PR: https://github.com/EmergeTools/SnapshotPreviews/pull/239
        return ["PaywallsTester.*", "RevenueCatUI.*"]
    }
}
