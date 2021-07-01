import XCTest
import Nimble

import Purchases

class SystemInfoTests: XCTestCase {
    func testproxyURL() {
        let defaultURL = URL(string: "https://api.revenuecat.com")
        expect(SystemInfo.serverHostURL) == defaultURL
        expect(SystemInfo.proxyURL).to(beNil())

        let url = URL(string: "https://my_url")
        SystemInfo.proxyURL = url

        expect(SystemInfo.serverHostURL) == url
        expect(SystemInfo.proxyURL) == url

        SystemInfo.proxyURL = nil
        expect(SystemInfo.proxyURL).to(beNil())

        expect(SystemInfo.serverHostURL) == defaultURL
    }

    func testsystemVersion() {
        expect(SystemInfo.systemVersion) == ProcessInfo().operatingSystemVersionString
    }

    func testPlatformFlavor() {
        let flavor = "flavor"
        let systemInfo = try! SystemInfo(platformFlavor: flavor,
                                           platformFlavorVersion: "foo",
                                           finishTransactions: false)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let systemInfo = try! SystemInfo(platformFlavor: "foo",
                                           platformFlavorVersion: flavorVersion,
                                           finishTransactions: false)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testPlatformFlavorAndPlatformFlavorVersionMustSimultaneouslyExistOrNotExist() {
        expect(try SystemInfo(platformFlavor: "a",
                              platformFlavorVersion: "b",
                              finishTransactions: true))
            .toNot(throwError(SystemInfo.SystemInfoError.invalidInitializationData))

        expect(try SystemInfo(platformFlavor: nil,
                              platformFlavorVersion: "b",
                              finishTransactions: true))
            .to(throwError(SystemInfo.SystemInfoError.invalidInitializationData))

        expect(try SystemInfo(platformFlavor: "a",
                              platformFlavorVersion: nil,
                              finishTransactions: true))
            .to(throwError(SystemInfo.SystemInfoError.invalidInitializationData))

        expect(try SystemInfo(platformFlavor: nil,
                              platformFlavorVersion: nil,
                              finishTransactions: true))
            .toNot(throwError(SystemInfo.SystemInfoError.invalidInitializationData))
    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = try! SystemInfo(platformFlavor: nil,
                                           platformFlavorVersion: nil,
                                           finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions

        finishTransactions = true

        systemInfo = try! SystemInfo(platformFlavor: nil,
                                       platformFlavorVersion: nil,
                                       finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
    }
}
