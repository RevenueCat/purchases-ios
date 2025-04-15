//
//  rc_maestroUITestsLaunchTests.swift
//  rc_maestroUITests
//
//  Created by Facundo Menzella on 14/4/25.
//

import XCTest
import StoreKitTest

enum LaunchArguments {
    static let purchasedProductID = "purchasedProductID"
    static let storeKitConfigFile = "storeKitConfigFile"
}

enum LaunchArgumentsManager {

    // Check for presence of a flag like `-isUITestMode`
    static func contains(_ keyPath: KeyPath<LaunchArguments.Type, String>) -> Bool {
        let key = "-" + LaunchArguments.self[keyPath: keyPath]
        return CommandLine.arguments.contains(key)
    }

    // Extract value from something like `-purchasedProductID com.yourapp.premium`
    static func value(for keyPath: KeyPath<LaunchArguments.Type, String>) -> String? {
        let key = "-" + LaunchArguments.self[keyPath: keyPath]
        guard let index = CommandLine.arguments.firstIndex(of: key),
              CommandLine.arguments.indices.contains(index + 1)
        else {
            return nil
        }
        return CommandLine.arguments[index + 1]
    }
}

final class rc_maestroUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() async throws {
        do {
            let session = try SKTestSession(configurationFileNamed: "StoreKitConfigDefault")
            print("✅ Launching config StoreKitConfigDefault.")

            session.disableDialogs = true
            let products = session.allTransactions()
            session.clearTransactions()

            try await session.buyProduct(identifier: "maestro.weekly.tests")
            print("✅ Purchasing maestro.weekly.tests.")
        } catch {
            print("❌ Failed to configure StoreKitTestSession: \(error)")
            return
        }

        let app = XCUIApplication()
        app.launch()
    }
}
