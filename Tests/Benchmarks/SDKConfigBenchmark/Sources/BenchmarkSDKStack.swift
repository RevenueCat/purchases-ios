import Foundation

/// Builds the same manager-level object graph `Purchases` wires at configure time, minus
/// StoreKit and identity, so one simulated app launch is: construct a stack, kick the remote
/// config refresh (config modes), and fetch offerings through `OfferingsManager`.
///
/// Mode selection mirrors production's `SystemInfo.remoteConfigEnabled` gate: `legacy` passes
/// `remoteConfigManager: nil` to `OfferingsManager` (gate off), the config modes wire a real
/// `RemoteConfigManager` stack (gate on). The kill-switch mode uses identical wiring; the
/// fixture server's 4xx is what trips the manager's session kill switch.
final class BenchmarkSDKStack {

    let offeringsManager: OfferingsManager
    let remoteConfigManager: RemoteConfigManagerType?
    let httpClient: HTTPClient
    let deviceCache: DeviceCache

    private let appUserID: String

    init(mode: BenchmarkMode, apiKey: String, appUserID: String) {
        self.appUserID = appUserID

        let operationDispatcher = OperationDispatcher.default
        let systemInfo = Self.makeSystemInfo(apiKey: apiKey, operationDispatcher: operationDispatcher)

        let httpClient = HTTPClient(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            signing: Signing(apiKey: apiKey),
            diagnosticsTracker: nil,
            requestTimeout: 15,
            operationDispatcher: operationDispatcher
        )
        self.httpClient = httpClient

        let backendConfiguration = BackendConfiguration(
            httpClient: httpClient,
            operationDispatcher: operationDispatcher,
            operationQueue: Backend.QueueProvider.createBackendQueue(),
            diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: systemInfo,
            offlineCustomerInfoCreator: nil
        )
        let backend = Backend(
            backendConfig: backendConfiguration,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            )
        )

        guard let userDefaults = UserDefaults(suiteName: "com.revenuecat.SDKConfigBenchmark.scratch") else {
            preconditionFailure("Could not create benchmark UserDefaults suite")
        }
        let deviceCache = DeviceCache(systemInfo: systemInfo, userDefaults: userDefaults)
        self.deviceCache = deviceCache

        let remoteConfigManager = mode.usesRemoteConfig
            ? Self.makeRemoteConfigManager(backendConfiguration: backendConfiguration, appUserID: appUserID)
            : nil
        self.remoteConfigManager = remoteConfigManager

        self.offeringsManager = OfferingsManager(
            deviceCache: deviceCache,
            operationDispatcher: operationDispatcher,
            systemInfo: systemInfo,
            backend: backend,
            offeringsFactory: OfferingsFactory(systemInfo: systemInfo),
            productsManager: BenchmarkProductsManager(),
            diagnosticsTracker: nil,
            remoteConfigManager: remoteConfigManager
        )
    }

    /// Kicks the remote config sync the way `Purchases.updateAllCaches` does on launch.
    func refreshRemoteConfigIfWired() {
        self.remoteConfigManager?.refreshRemoteConfig(isAppBackgrounded: false)
    }

    /// Erases every piece of disk state a previous launch could have left behind, so a `cold`
    /// iteration starts from nothing: ETags, the offerings disk cache, and the persisted remote
    /// configuration with its blob store.
    func clearAllDiskState() {
        self.httpClient.clearCaches()
        self.deviceCache.clearOfferingsCache(appUserID: self.appUserID)
        self.remoteConfigManager?.clearCache()
    }

}

private extension BenchmarkSDKStack {

    static func makeSystemInfo(apiKey: String, operationDispatcher: OperationDispatcher) -> SystemInfo {
        return SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            operationDispatcher: operationDispatcher,
            storeKitVersion: .storeKit1,
            apiKey: apiKey,
            responseVerificationMode: .disabled,
            isAppBackgrounded: false,
            preferredLocalesProvider: PreferredLocalesProvider(
                preferredLocaleOverride: "en_US",
                systemPreferredLocalesGetter: { ["en_US"] }
            )
        )
    }

    static func makeRemoteConfigManager(
        backendConfiguration: BackendConfiguration,
        appUserID: String
    ) -> RemoteConfigManagerType {
        let diskCache = RemoteConfigDiskCache()
        let blobStore = RemoteConfigBlobStore()
        let sourceProvider = RemoteConfigSourceProvider(topicStore: diskCache)
        let blobFetcher = RemoteConfigBlobFetcher(
            blobStore: blobStore,
            sourceProvider: sourceProvider,
            downloader: URLSessionRemoteConfigBlobDownloader(
                session: SimulatedTransportURLProtocol.makeSession()
            )
        )
        return RemoteConfigManager(
            remoteConfigAPI: RemoteConfigAPI(backendConfig: backendConfiguration),
            diskCache: diskCache,
            blobStore: blobStore,
            blobFetcher: blobFetcher,
            currentUserProvider: BenchmarkCurrentUserProvider(appUserID: appUserID)
        )
    }

}

private struct BenchmarkCurrentUserProvider: CurrentUserProvider {

    let appUserID: String

    var currentAppUserID: String { return self.appUserID }
    var currentUserIsAnonymous: Bool { return false }

}
