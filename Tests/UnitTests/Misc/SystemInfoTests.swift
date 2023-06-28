import Nimble
import XCTest

@testable import RevenueCat

#if os(watchOS)
import WatchKit
#endif

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
        expect(systemInfo.observerMode) == !finishTransactions

        finishTransactions = true

        systemInfo = try SystemInfo(platformInfo: nil,
                                    finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions
    }

    func testIsSandbox() throws {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: true)

        expect(try SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == true
        expect(try SystemInfo.withReceiptResult(.receiptWithData, sandboxDetector).isSandbox) == true
    }

    func testIsNotSandbox() throws {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: false)

        expect(try SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == false
        expect(try SystemInfo.withReceiptResult(.receiptWithData, sandboxDetector).isSandbox) == false
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

    func testReceiptFetchRetryIsDisabledByDefault() {
        expect(SystemInfo.default.dangerousSettings.internalSettings.enableReceiptFetchRetry) == false
    }

    // MARK: - identifierForVendor

    #if os(iOS) || os(tvOS)

    func testIdentifierForVendor() {
        expect(SystemInfo.default.identifierForVendor) == UIDevice.current.identifierForVendor?.uuidString
    }

    #elseif os(watchOS)

    func testIdentifierForVendor() {
        expect(SystemInfo.default.identifierForVendor) == WKInterfaceDevice.current().identifierForVendor?.uuidString
    }

    #elseif os(macOS) || targetEnvironment(macCatalyst)

    func testIdentifierForVendorInSandbox() {
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(true)
        )

        expect(info.identifierForVendor) == MacDevice.identifierForVendor?.uuidString
    }

    func testIdentifierForVendorNotSandbox() {
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(false)
        )

        expect(info.identifierForVendor).to(beNil())
    }

    #else

    func testIdentifierForVendorIsNil() {
        expect(SystemInfo.default.identifierForVendor).to(beNil())
    }

    #endif

}

private extension SystemInfo {

    static func withReceiptResult(
        _ result: MockBundle.ReceiptURLResult,
        _ sandboxEnvironmentDetector: SandboxEnvironmentDetector? = nil
    ) throws -> SystemInfo {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let sandboxDetector = sandboxEnvironmentDetector ?? BundleSandboxEnvironmentDetector(bundle: bundle)

        return try SystemInfo(platformInfo: nil,
                              finishTransactions: false,
                              bundle: bundle,
                              sandboxEnvironmentDetector: sandboxDetector)
    }

    static var `default`: SystemInfo {
        // swiftlint:disable:next force_try
        return try! .init(platformInfo: nil, finishTransactions: true)
    }

}
