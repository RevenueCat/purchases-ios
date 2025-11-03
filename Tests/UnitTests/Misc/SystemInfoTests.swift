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
        let systemInfo = SystemInfo(platformInfo: platformInfo,
                                    finishTransactions: false,
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let platformInfo = Purchases.PlatformInfo(flavor: "foo", version: flavorVersion)
        let systemInfo = SystemInfo(platformInfo: platformInfo,
                                    finishTransactions: false,
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = SystemInfo(platformInfo: nil,
                                    finishTransactions: finishTransactions,
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions

        finishTransactions = true

        systemInfo = SystemInfo(platformInfo: nil,
                                finishTransactions: finishTransactions,
                                preferredLocalesProvider: .mock())
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

    func testPreferredLocalesWithLocaleOverride() {
        let localesProvider: PreferredLocalesProvider = .mock(preferredLocaleOverride: "es_ES",
                                                              locales: ["fr_FR", "de_DE", "en_US"])
        let info = SystemInfo(platformInfo: nil,
                              finishTransactions: false,
                              preferredLocalesProvider: localesProvider)
        expect(info.preferredLocales).to(equal(["es_ES", "fr_FR", "de_DE", "en_US"]))
    }

    func testPreferredLocalesWithoutLocaleOverride() {
        let localesProvider: PreferredLocalesProvider = .mock(preferredLocaleOverride: nil,
                                                              locales: ["fr_FR", "de_DE", "en_US"])
        let info = SystemInfo(platformInfo: nil,
                              finishTransactions: false,
                              preferredLocalesProvider: localesProvider)
        expect(info.preferredLocales).to(equal(["fr_FR", "de_DE", "en_US"]))
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
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
            preferredLocalesProvider: .mock()
        )

        expect(info.identifierForVendor) == MacDevice.identifierForVendor?.uuidString
    }

    func testIdentifierForVendorNotSandbox() {
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: false),
            preferredLocalesProvider: .mock()
        )

        expect(info.identifierForVendor).to(beNil())
    }

    #else

    func testIdentifierForVendorIsNil() {
        expect(SystemInfo.default.identifierForVendor).to(beNil())
    }

    #endif

    // MARK: - apiBaseURL

    func testDefaultAPIBaseURL() {
        expect(SystemInfo.apiBaseURL.absoluteString) == "https://api.revenuecat.com"
    }

    func testSettingAPIBaseURL() {
        let originalURL = SystemInfo.apiBaseURL
        defer { SystemInfo.apiBaseURL = originalURL }

        let customURL = URL(string: "https://custom.example.com")!
        SystemInfo.apiBaseURL = customURL

        expect(SystemInfo.apiBaseURL) == customURL
    }

    func testAPIBaseURLPersistsAcrossGets() {
        let originalURL = SystemInfo.apiBaseURL
        defer { SystemInfo.apiBaseURL = originalURL }

        let customURL = URL(string: "https://test.example.com")!
        SystemInfo.apiBaseURL = customURL

        expect(SystemInfo.apiBaseURL) == customURL
        expect(SystemInfo.apiBaseURL) == customURL
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

        return SystemInfo(platformInfo: nil,
                          finishTransactions: false,
                          bundle: bundle,
                          sandboxEnvironmentDetector: sandboxDetector,
                          preferredLocalesProvider: .mock())
    }

    static var `default`: SystemInfo {
        return .init(platformInfo: nil,
                     finishTransactions: true,
                     preferredLocalesProvider: .mock())
    }

}
