import Nimble
import XCTest

@testable import RevenueCat

class SystemInfoTests: TestCase {

    func testProxyURL() {
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

    func testSystemVersion() {
        expect(SystemInfo.systemVersion) == ProcessInfo().operatingSystemVersionString
    }

    func testPlatformFlavor() throws {
        let flavor = "flavor"
        let platformInfo = Purchases.PlatformInfo(flavor: flavor, version: "foo")
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: false)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() throws {
        let flavorVersion = "flavorVersion"
        let platformInfo = Purchases.PlatformInfo(flavor: "foo", version: flavorVersion)
        let systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: false)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testFinishTransactions() throws {
        var finishTransactions = false
        var systemInfo = try SystemInfo(platformInfo: nil,
                                        finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions

        finishTransactions = true

        systemInfo = try SystemInfo(platformInfo: nil,
                                    finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
    }

    func testIsSandbox() throws {
        expect(try SystemInfo.withReceiptResult(.sandboxReceipt).isSandbox) == true
    }

    func testIsNotSandbox() throws {
        expect(try SystemInfo.withReceiptResult(.receiptWithData).isSandbox) == false
    }

    func testIsNotSandboxIfNoReceiptURL() throws {
        expect(try SystemInfo.withReceiptResult(.nilURL).isSandbox) == false
    }

    func testIsAppleSubscriptionURLWithAnotherURL() {
        expect(SystemInfo.isAppleSubscription(managementURL: URL(string: "www.google.com")!)) == false
    }

    func testIsAppleSubscriptionURLWithStandardURL() {
        expect(SystemInfo.isAppleSubscription(managementURL: SystemInfo.appleSubscriptionsURL)) == true
    }

    func testIsAppleSubscriptionURLWithShortenedURL() {
        expect(SystemInfo.isAppleSubscription(
            managementURL: URL(string: "https://rev.cat/manage-apple-subscription")!
        )) == false
    }

}

private extension SystemInfo {

    static func withReceiptResult(_ result: MockBundle.ReceiptURLResult) throws -> SystemInfo {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        return try SystemInfo(platformInfo: nil,
                              finishTransactions: false,
                              bundle: bundle)
    }

}
