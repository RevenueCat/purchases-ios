import SwiftUI
@testable import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }
        Purchases.configure(
            with: .builder(withAPIKey: Constants.apiKey)
                .with(dangerousSettings: .init(
                    autoSyncPurchases: true,
                    internalSettings: DangerousSettings.Internal(
                        forceServerErrorStrategy: .init { request in
                            switch Constants.forceServerErrorStrategy {
                            case .never:
                                return false
                            case .primaryDomainDown:
                                return request.fallbackHostIndex == nil
                            }
                        }
                    )
                ))
                .build()
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
