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
        expectToNotThrowException {
            _ = RCSystemInfo(platformFlavor: "a", platformFlavorVersion: "b", finishTransactions: true)
        }
        expectToThrowException(.parameterAssert) {
            _ = RCSystemInfo(platformFlavor: nil, platformFlavorVersion: "b", finishTransactions: true)
        }
        expectToThrowException(.parameterAssert) {
            _ = RCSystemInfo(platformFlavor: "a", platformFlavorVersion: nil, finishTransactions: true)
        }
            
        expectToNotThrowException {
            _ = RCSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
        }
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

    func testIsSandboxInSimulator() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.sandboxReceipt),
                                      inSimulator: true)) == true
    }

    func testIsSandboxOnDevice() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.sandboxReceipt),
                                      inSimulator: false)) == true
    }

    func testIsAlwaysSandboxInSimulator() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.productionReceipt),
                                      inSimulator: true)) == true
    }

    func testIsNotSandboxWithRealReceipt() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.productionReceipt),
                                      inSimulator: false)) == false
    }

    func testMASSandbox() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.macOSSandboxReceipt),
                                      inSimulator: false)) == true
    }

    func testMASProduction() {
        expect(RCSystemInfo.isSandbox(with: MockBundle(.macOSAppStoreReceipt),
                                      inSimulator: false)) == false
    }

}

// MARK: -

private final class MockBundle: Bundle {

    enum ReceiptURLResult {

        case sandboxReceipt
        case productionReceipt
        case macOSAppStoreReceipt
        case macOSSandboxReceipt
        case nilURL

    }

    let receiptURLResult: ReceiptURLResult

    init(_ receiptURLResult: ReceiptURLResult) {
        self.receiptURLResult = receiptURLResult
        super.init()
    }

    override var appStoreReceiptURL: URL? {
        switch self.receiptURLResult {
        case .sandboxReceipt:
            return URL(string: "file:///private/var/mobile/Containers/Data/Application/8E17D2EF-7F56-4332-9A5B-6EABD08EFC47/StoreKit/sandboxReceipt")!
        case .productionReceipt:
            return URL(string: "file:///private/var/mobile/Containers/Data/Application/8E17D2EF-7F56-4332-9A5B-6EABD08EFC47/StoreKit/receipt")!
        case .macOSSandboxReceipt:
            // swiftlint:disable:next line_length
            return URL(string: "/Users/nachosoto/Library/Developer/Xcode/DerivedData/PurchaseTester-coxthvoqhbhicvcmwbbwnogtdrle/Build/Products/Debug-maccatalyst/PurchaseTester.app/Contents/_MASReceipt/receipt")!
        case .macOSAppStoreReceipt:
            return URL(string: "/Applications/PurchaseTester.app/Contents/_MASReceipt/receipt")!
        case .nilURL:
            return nil
        }
    }

}
