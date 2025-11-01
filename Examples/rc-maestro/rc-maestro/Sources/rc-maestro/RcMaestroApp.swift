import SwiftUI
@testable import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }
        
        // Used in E2E tests
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
                                return request.fallbackUrlIndex == nil
                            }
                        }
                    )
                ))
                .build()
        )
    }

    var body: some Scene {
        WindowGroup {
            switch e2eTestFlow {
            case .some(let flow):
                flow.view
            case nil:
                ContentView()
            }
        }
    }
    
    /*
     Parses the launch argument with the e2e test flow to run
     */
    fileprivate var e2eTestFlow: E2ETestFlow? {
        guard let string = UserDefaults.standard.dictionaryRepresentation()["e2e_test_flow"] as? String else {
            return nil
        }
        
        return E2ETestFlow(rawValue: string) ?? nil
    }
}

enum E2ETestFlow: String {
    case subscribeFromV1Paywall = "subscribe_from_v1_paywall"
    case subscribeFromV2Paywall = "subscribe_from_v2_paywall"
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .subscribeFromV1Paywall:
            E2ETestFlowView.SubscriberFromV1Paywall()
        case .subscribeFromV2Paywall:
            E2ETestFlowView.SubscriberFromV2Paywall()
        }
    }
}

enum E2ETestFlowView {}
