//
//  TempBundledDecodeTests.swift
//

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class TempBundledDecodeTests: TestCase {

    private static let repoRoot = "/Users/alexrepty/Documents/GitHub/purchases-ios"
    private static let bundledDir =
        "\(repoRoot)/Tests/TestingApps/PaywallsTester/PaywallsTester/Config/BundledPaywalls"

    func testDecodeDog() throws {
        try decode(file: "components-dog")
    }

    func testDecodeCat() throws {
        try decode(file: "components-cat")
    }

    private func decode(file: String) throws {
        let url = URL(fileURLWithPath: "\(Self.bundledDir)/\(file).json")
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let config = try decoder.decode(
                PaywallComponentsData.ComponentsConfig.self,
                from: data
            )
            print("DECODE OK \(file): components=\(config.base.stack.components.count)")
        } catch {
            print("DECODE FAILED \(file): \(error)")
            throw error
        }
    }

}
