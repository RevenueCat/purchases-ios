import XCTest
import Nimble

import Purchases

class SystemInfoTests: XCTestCase {
    func testProxyURL() {
        let defaultURL = "api.revenuecat.com"
        expect(RCSystemInfo.serverHostName()) == defaultURL
        expect(RCSystemInfo.proxyURL()).to(beNil())

        let url = "my_url"
        RCSystemInfo.setProxyURL(url)

        expect(RCSystemInfo.serverHostName()) == url
        expect(RCSystemInfo.proxyURL()) == url

        RCSystemInfo.setProxyURL(nil)
        expect(RCSystemInfo.proxyURL()).to(beNil())

        expect(RCSystemInfo.serverHostName()) == defaultURL
    }

    func testServerProtocol() {
        expect(RCSystemInfo.serverProtocol()) == "https"
    }

    func testSystemVersion() {
        expect(RCSystemInfo.systemVersion()) == ProcessInfo().operatingSystemVersionString
    }

    func testPlatformFlavor() {
        let flavor = "flavor"
        let systemInfo = RCSystemInfo(platformFlavor: flavor,
                                      platformFlavorVersion: "foo",
                                      finishTransactions: false)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let systemInfo = RCSystemInfo(platformFlavor: "foo",
                                      platformFlavorVersion: flavorVersion,
                                      finishTransactions: false)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testPlatformFlavorAndPlatformFlavorVersionMustSimultaneouslyExistOrNotExist() {
        expect { RCSystemInfo(platformFlavor: "a", platformFlavorVersion: "b", finishTransactions: true) }
            .notTo(raiseException())
        expect { RCSystemInfo(platformFlavor: nil, platformFlavorVersion: "b", finishTransactions: true) }
            .to(raiseException())
        expect { RCSystemInfo(platformFlavor: "a", platformFlavorVersion: nil, finishTransactions: true) }
            .to(raiseException())
        expect { RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true) }
            .notTo(raiseException())
    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = RCSystemInfo(platformFlavor: nil,
                                      platformFlavorVersion: nil,
                                      finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions

        finishTransactions = true

        systemInfo = RCSystemInfo(platformFlavor: nil,
                                  platformFlavorVersion: nil,
                                  finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
    }
}