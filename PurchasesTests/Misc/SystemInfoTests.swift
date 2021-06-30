import XCTest
import Nimble

import Purchases

class SystemInfoTests: XCTestCase {
    func testProxyURL() {
        let defaultURL = URL(string: "https://api.revenuecat.com")
        expect(RCSystemInfo.serverHostURL()) == defaultURL
        expect(RCSystemInfo.proxyURL()).to(beNil())

        let url = URL(string: "https://my_url")
        RCSystemInfo.setProxyURL(url)

        expect(RCSystemInfo.serverHostURL()) == url
        expect(RCSystemInfo.proxyURL()) == url

        RCSystemInfo.setProxyURL(nil)
        expect(RCSystemInfo.proxyURL()).to(beNil())

        expect(RCSystemInfo.serverHostURL()) == defaultURL
    }

    func testSystemVersion() {
        expect(RCSystemInfo.systemVersion()) == ProcessInfo().operatingSystemVersionString
    }

    func testPlatformFlavor() {
        let flavor = "flavor"
        let systemInfo = try! RCSystemInfo(platformFlavor: flavor,
                                           platformFlavorVersion: "foo",
                                           finishTransactions: false)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let systemInfo = try! RCSystemInfo(platformFlavor: "foo",
                                           platformFlavorVersion: flavorVersion,
                                           finishTransactions: false)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testPlatformFlavorAndPlatformFlavorVersionMustSimultaneouslyExistOrNotExist() {
        expect(try RCSystemInfo(platformFlavor: "a", platformFlavorVersion: "b", finishTransactions: true)).toNot(throwError(RCSystemInfo.SystemInfoError.invalidInitializationData))

        expect(try RCSystemInfo(platformFlavor: nil, platformFlavorVersion: "b", finishTransactions: true)).to(throwError(RCSystemInfo.SystemInfoError.invalidInitializationData))

        expect(try RCSystemInfo(platformFlavor: "a", platformFlavorVersion: nil, finishTransactions: true)).to(throwError(RCSystemInfo.SystemInfoError.invalidInitializationData))

        expect(try RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)).toNot(throwError(RCSystemInfo.SystemInfoError.invalidInitializationData))

    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = try! RCSystemInfo(platformFlavor: nil,
                                           platformFlavorVersion: nil,
                                           finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions

        finishTransactions = true

        systemInfo = try! RCSystemInfo(platformFlavor: nil,
                                      platformFlavorVersion: nil,
                                      finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
    }
}
