import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

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
                                    apiKey: "api_key",
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.platformFlavor) == flavor
    }

    func testPlatformFlavorVersion() {
        let flavorVersion = "flavorVersion"
        let platformInfo = Purchases.PlatformInfo(flavor: "foo", version: flavorVersion)
        let systemInfo = SystemInfo(platformInfo: platformInfo,
                                    finishTransactions: false,
                                    apiKey: "api_key",
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.platformFlavorVersion) == flavorVersion
    }

    func testInstallationMethodIsNotEmpty() {
        let method = SystemInfo.installationMethod
        expect(method).toNot(beEmpty())
        expect(["spm", "cocoapods", "carthage_source", "xcframework", "unknown"]).to(contain(method))
    }

    func testFinishTransactions() {
        var finishTransactions = false
        var systemInfo = SystemInfo(platformInfo: nil,
                                    finishTransactions: finishTransactions,
                                    apiKey: "api_key",
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.finishTransactions) == finishTransactions
        expect(systemInfo.observerMode) == !finishTransactions

        finishTransactions = true

        systemInfo = SystemInfo(platformInfo: nil,
                                finishTransactions: finishTransactions,
                                apiKey: "api_key",
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

    func testIsSandboxIsComputedOnlyOnceWhenAccessedConcurrently() {
        let sandboxDetector = SynchronizingSandboxEnvironmentDetector()
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            sandboxEnvironmentDetector: sandboxDetector,
            apiKey: "api_key",
            preferredLocalesProvider: .mock()
        )
        let workersReady = DispatchSemaphore(value: 0)
        let startWorkers = DispatchSemaphore(value: 0)
        let workersFinished = DispatchGroup()

        for _ in 0..<2 {
            workersFinished.enter()
            DispatchQueue.global().async {
                workersReady.signal()
                startWorkers.wait()
                _ = systemInfo.isSandbox
                workersFinished.leave()
            }
        }

        workersReady.wait()
        workersReady.wait()
        startWorkers.signal()
        startWorkers.signal()
        workersFinished.wait()

        expect(sandboxDetector.callCount) == 1
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
                              apiKey: "api_key",
                              preferredLocalesProvider: localesProvider)
        expect(info.preferredLocales).to(equal(["es_ES", "fr_FR", "de_DE", "en_US"]))
    }

    func testPreferredLocalesWithoutLocaleOverride() {
        let localesProvider: PreferredLocalesProvider = .mock(preferredLocaleOverride: nil,
                                                              locales: ["fr_FR", "de_DE", "en_US"])
        let info = SystemInfo(platformInfo: nil,
                              finishTransactions: false,
                              apiKey: "api_key",
                              preferredLocalesProvider: localesProvider)
        expect(info.preferredLocales).to(equal(["fr_FR", "de_DE", "en_US"]))
    }

    func testPreferredLocalesPrioritizesAppLanguageOverDeviceLanguage() {
        let provider: PreferredLocalesProvider = .mock(bundlePreferredLocale: "en",
                                                       locales: ["zh-Hans", "fr_FR"])
        provider.setPreferApplicationLocale(true)

        expect(provider.preferredLocales) == ["en", "zh-Hans", "fr_FR"]
    }

    func testPreferredLocalesOverrideTakesPrecedenceOverAppLanguage() {
        let provider: PreferredLocalesProvider = .mock(preferredLocaleOverride: "es_ES",
                                                       bundlePreferredLocale: "en",
                                                       locales: ["zh-Hans", "fr_FR"])
        provider.setPreferApplicationLocale(true)

        expect(provider.preferredLocales) == ["es_ES", "en", "zh-Hans", "fr_FR"]

        provider.overridePreferredLocale(nil)

        expect(provider.preferredLocales) == ["en", "zh-Hans", "fr_FR"]
    }

    func testPreferredLocalesIgnoresAppLanguageByDefault() {
        let provider: PreferredLocalesProvider = .mock(bundlePreferredLocale: "en", locales: ["zh-Hans"])

        expect(provider.preferredLocales) == ["zh-Hans"]
    }

    func testDisablingAppLanguagePreservesExplicitOverride() {
        let provider: PreferredLocalesProvider = .mock(preferredLocaleOverride: "es_ES",
                                                       bundlePreferredLocale: "en",
                                                       locales: ["zh-Hans"])
        provider.setPreferApplicationLocale(true)
        provider.setPreferApplicationLocale(false)

        expect(provider.preferredLocales) == ["es_ES", "zh-Hans"]
    }

    func testPreferringAppLanguageFallsBackWhenBundleHasNoLocalization() {
        let provider: PreferredLocalesProvider = .mock(locales: ["zh-Hans"])
        provider.setPreferApplicationLocale(true)

        expect(provider.preferredLocales) == ["zh-Hans"]
    }

    func testAppLanguagePreservesRegionalPaywallLocale() {
        let cases: [(app: String, system: [String], available: [String], expected: String)] = [
            ("en", ["en-GB"], ["en_US", "en_GB"], "en_GB"),
            ("pt", ["pt-PT"], ["pt_BR", "pt_PT"], "pt_PT"),
            ("en", ["zh-Hans", "en-GB"], ["zh_Hans", "en_US", "en_GB"], "en_GB"),
            ("en", ["zh-Hans"], ["zh_Hans", "en_US"], "en_US"),
            ("en_US", ["en-GB"], ["en_US", "en_GB"], "en_US"),
            ("zh-Hans", ["zh-Hant-TW"], ["zh_Hans", "zh_Hant"], "zh_Hans")
        ]

        for testCase in cases {
            let provider: PreferredLocalesProvider = .mock(bundlePreferredLocale: testCase.app,
                                                           locales: testCase.system)
            provider.setPreferApplicationLocale(true)

            let selectedLocale = Locale.selectPreferredLocale(
                from: testCase.available.map(Locale.init(identifier:)),
                preferredLocales: provider.preferredLocales.map(Locale.init(identifier:))
            )

            expect(selectedLocale).to(equal(Locale(identifier: testCase.expected)),
                                      description: "App \(testCase.app), system \(testCase.system)")
        }
    }

    func testAppLanguagePromotionDeduplicatesLocalesAndPreservesOverride() {
        let provider: PreferredLocalesProvider = .mock(preferredLocaleOverride: "fr_FR",
                                                       bundlePreferredLocale: "en",
                                                       locales: ["zh-Hans", "en-GB", "en", "fr_FR"])
        provider.setPreferApplicationLocale(true)

        expect(provider.preferredLocales) == ["fr_FR", "en-GB", "en", "zh-Hans"]
        expect(Locale.selectPreferredLocale(
            from: [Locale(identifier: "en_GB"), Locale(identifier: "fr_FR")],
            preferredLocales: provider.preferredLocales.map(Locale.init(identifier:))
        )) == Locale(identifier: "fr_FR")
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
            apiKey: "api_key",
            preferredLocalesProvider: .mock()
        )

        expect(info.identifierForVendor) == MacDevice.identifierForVendor?.uuidString
    }

    func testIdentifierForVendorNotSandbox() {
        let info = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: false),
            apiKey: "api_key",
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

    func testRemoteConfigEnabledByDefault() {
        let systemInfo = SystemInfo(platformInfo: nil,
                                    finishTransactions: true,
                                    apiKey: "api_key",
                                    dangerousSettings: DangerousSettings(),
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.remoteConfigEnabled) == true
    }

    func testRemoteConfigDisabledUnderCustomEntitlementComputation() {
        let dangerousSettings = DangerousSettings(
            autoSyncPurchases: true,
            customEntitlementComputation: true,
            internalSettings: DangerousSettings.Internal.default
        )
        let systemInfo = SystemInfo(platformInfo: nil,
                                    finishTransactions: true,
                                    apiKey: "api_key",
                                    dangerousSettings: dangerousSettings,
                                    preferredLocalesProvider: .mock())
        expect(systemInfo.remoteConfigEnabled) == false
    }

}

private final class SynchronizingSandboxEnvironmentDetector: SandboxEnvironmentDetector, @unchecked Sendable {

    private let calls: Atomic<Int> = .init(0)
    private let secondCallStarted = DispatchSemaphore(value: 0)

    var callCount: Int { self.calls.value }

    var isSandbox: Bool {
        let callCount = self.calls.increment()

        if callCount == 1 {
            _ = self.secondCallStarted.wait(timeout: .now() + 0.25)
        } else {
            self.secondCallStarted.signal()
        }

        return true
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
                          apiKey: "api_key",
                          preferredLocalesProvider: .mock())
    }

    static var `default`: SystemInfo {
        return .init(platformInfo: nil,
                     finishTransactions: true,
                     apiKey: "api_key",
                     preferredLocalesProvider: .mock())
    }

}
