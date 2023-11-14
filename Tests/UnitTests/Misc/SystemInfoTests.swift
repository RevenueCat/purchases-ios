import Nimble
import XCTest

@testable import RevenueCat

#if os(watchOS)
import WatchKit
#endif

class SystemInfoTests: TestCase {

    func testSystemVersion() {
        expect(SystemInfo.systemVersion) == ProcessInfo().operatingSystemVersionString
    }

    func testPlatformFlavor() {
        let flavor = "flavor"
        let platformInfo = Purchases.PlatformInfo(flavor: flavor, version: "foo")
        let systemInfo = SystemInfo(platformInfo: platformInfo, finishTransactions: false)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let platformInfo = Purchases.PlatformInfo(flavor: "foo", version: flavorVersion)
        let systemInfo = SystemInfo(platformInfo: platformInfo, finishTransactions: false)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = SystemInfo(platformInfo: nil, finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions

        finishTransactions = true

        systemInfo = SystemInfo(platformInfo: nil, finishTransactions: finishTransactions)
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions
    }

    func testIsSandbox() {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: true)

        expect(SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == true
        expect(SystemInfo.withReceiptResult(.receiptWithData, sandboxDetector).isSandbox) == true
    }

    func testIsNotSandbox() {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: false)

        expect(SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == false
        expect(SystemInfo.withReceiptResult(.receiptWithData, sandboxDetector).isSandbox) == false
    }

    func testStorefrontForUnsupportedPlatform() {
        let storefront = SystemInfo(platformInfo: nil, finishTransactions: false).storefront

        // See `StorefrontTests` for real tests
        if #unavailable(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1) {
            expect(storefront).to(beNil())
        }
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

    #if os(iOS) || os(tvOS) || VISION_OS

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
    ) -> SystemInfo {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let sandboxDetector = sandboxEnvironmentDetector ?? BundleSandboxEnvironmentDetector(bundle: bundle)

        return SystemInfo(platformInfo: nil,
                          finishTransactions: false,
                          bundle: bundle,
                          sandboxEnvironmentDetector: sandboxDetector)
    }

    static var `default`: SystemInfo {
        return .init(platformInfo: nil, finishTransactions: true)
    }

}
