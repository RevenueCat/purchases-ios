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
        let deviceCache = MockDeviceCache()
        let platformInfo = Purchases.PlatformInfo(flavor: flavor, version: "foo")
        let systemInfo = SystemInfo(platformInfo: platformInfo, finishTransactions: false, deviceCache: deviceCache)
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let platformInfo = Purchases.PlatformInfo(flavor: "foo", version: flavorVersion)
        let deviceCache = MockDeviceCache()
        let systemInfo = SystemInfo(platformInfo: platformInfo, finishTransactions: false, deviceCache: deviceCache)
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testFinishTransactions() {
        var finishTransactions = false
        let deviceCache = MockDeviceCache()
        var systemInfo = SystemInfo(platformInfo: nil, finishTransactions: finishTransactions, deviceCache: deviceCache)
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions

        finishTransactions = true

        systemInfo = SystemInfo(platformInfo: nil, finishTransactions: finishTransactions, deviceCache: deviceCache)
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions
    }

    func testIsSandbox() {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: true)

        expect(SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == true
        expect(SystemInfo.withReceiptResult(.appStoreReceipt, sandboxDetector).isSandbox) == true
    }

    func testIsNotSandbox() {
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: false)

        expect(SystemInfo.withReceiptResult(.sandboxReceipt, sandboxDetector).isSandbox) == false
        expect(SystemInfo.withReceiptResult(.appStoreReceipt, sandboxDetector).isSandbox) == false
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
        let deviceCache = MockDeviceCache()
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
            deviceCache: deviceCache
        )

        expect(info.identifierForVendor) == MacDevice.identifierForVendor?.uuidString
    }

    func testIdentifierForVendorNotSandbox() {
        let deviceCache = MockDeviceCache()
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: false),
            deviceCache: deviceCache
        )

        expect(info.identifierForVendor).to(beNil())
    }

    #else

    func testIdentifierForVendorIsNil() {
        expect(SystemInfo.default.identifierForVendor).to(beNil())
    }

    #endif

    // MARK: - Storefront Cache Tests
    func testUsesStorefrontFromCache() {
        let expectedStorefront = CodableStorefront(countryCode: "mock_country_code", identifier: "mock_id")
        let deviceCache = MockDeviceCache()
        deviceCache.cache(storefront: expectedStorefront)

        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
            deviceCache: deviceCache
        )

        expect(deviceCache.invokedReadCachedStorefront).to(beTrue())
        expect(info.storefront).toNot(beNil())
        expect(info.storefront?.countryCode).to(equal(expectedStorefront.countryCode))
        expect(info.storefront?.identifier).to(equal(expectedStorefront.identifier))
    }

    func testUsesStorefrontFromStoreKitIfNotCached() {
        let deviceCache = MockDeviceCache()
        expect(deviceCache.cachedStorefront()).to(beNil())

        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
            deviceCache: deviceCache
        )

        expect(deviceCache.invokedReadCachedStorefront).to(beTrue())

        expect(info.storefront).toEventuallyNot(beNil())
        expect(info.storefront?.countryCode).toEventuallyNot(beNil())
        expect(info.storefront?.countryCode).toEventuallyNot(beEmpty())
        expect(info.storefront?.identifier).toEventuallyNot(beNil())
        expect(info.storefront?.identifier).toEventuallyNot(beEmpty())
    }

    func testInitializingSystemInfoCachesStorefront() {
        let deviceCache = MockDeviceCache()

        _ = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
            deviceCache: deviceCache
        )

        expect(deviceCache.invokedReadCachedStorefront).to(beTrue())

        expect(deviceCache.invokedCacheStorefront).toEventually(beTrue())
        expect(deviceCache.cachedStorefront()).toEventuallyNot(beNil())
        expect(deviceCache.cachedStorefront()?.countryCode).toEventuallyNot(beNil())
        expect(deviceCache.cachedStorefront()?.countryCode).toEventuallyNot(beEmpty())
        expect(deviceCache.cachedStorefront()?.identifier).toEventuallyNot(beNil())
        expect(deviceCache.cachedStorefront()?.identifier).toEventuallyNot(beEmpty())

    }
}

private extension SystemInfo {

    static func withReceiptResult(
        _ result: MockBundle.ReceiptURLResult,
        _ sandboxEnvironmentDetector: SandboxEnvironmentDetector? = nil
    ) -> SystemInfo {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let sandboxDetector = sandboxEnvironmentDetector ?? BundleSandboxEnvironmentDetector(bundle: bundle)

        let deviceCache = MockDeviceCache()
        return SystemInfo(platformInfo: nil,
                          finishTransactions: false,
                          bundle: bundle,
                          sandboxEnvironmentDetector: sandboxDetector,
                          deviceCache: deviceCache)
    }

    static var `default`: SystemInfo {
        return .init(platformInfo: nil, finishTransactions: true, deviceCache: MockDeviceCache())
    }

}
