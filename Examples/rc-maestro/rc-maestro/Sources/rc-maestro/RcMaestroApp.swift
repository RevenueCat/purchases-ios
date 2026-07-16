import SwiftUI
@testable import RevenueCat

@main
struct RcMaestroApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }

        // Set API base URL if provided (used in E2E tests)
        if let apiBaseURL = Constants.apiBaseURL {
            SystemInfo.apiBaseURL = apiBaseURL
        }

        // Used in E2E tests
        Purchases.configure(
            with: .builder(withAPIKey: Constants.apiKey)
                .with(dangerousSettings: .init(
                    autoSyncPurchases: true,
                    internalSettings: DangerousSettings.Internal(
                        forceServerErrorStrategy: .init(
                            fakeResponseWithoutPerformingRequest: { request in
                                // Simulate a 4xx on the /v1/config endpoint (its session kill-switch),
                                // so we can exercise the classic-paywall fallback for workflow offerings.
                                guard case .remoteConfigNotFound = Constants.forceServerErrorStrategy,
                                      request.path.contains("config/"),
                                      let url = URL(string: "https://api.revenuecat.com"),
                                      let response = HTTPURLResponse(url: url,
                                                                     statusCode: 404,
                                                                     httpVersion: nil,
                                                                     headerFields: nil) else {
                                    return nil
                                }
                                return (response, Data("{}".utf8))
                            },
                            shouldForceServerError: { request in
                                switch Constants.forceServerErrorStrategy {
                                case .never, .remoteConfigNotFound:
                                    return false
                                case .primaryBackendDown:
                                    // Remote config uses a separate request path whose primary URL is already
                                    // the fallback backend, so it does not have a fallbackUrlIndex.
                                    if let fallbackPath = request.httpRequest.path as? HTTPRequest.FallbackPath,
                                       case .remoteConfig = fallbackPath {
                                        return false
                                    }
                                    return request.fallbackUrlIndex == nil
                                }
                            }
                        )
                    ),
                    // Workflows (multipage paywalls) read through remote config; this internal flag
                    // is the runtime gate (no compile flag needed for the Maestro app).
                    useWorkflows: true
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
        
        return E2ETestFlow(rawValue: string)
    }
}

enum E2ETestFlow: String {
    case subscribeFromV1Paywall = "subscribe_from_v1_paywall"
    case subscribeFromV2Paywall = "subscribe_from_v2_paywall"
    case openWorkflow = "open_workflow"
    case openNoPaywall = "open_no_paywall"
    case openWorkflowPresented = "open_workflow_presented"

    @ViewBuilder
    var view: some View {
        switch self {
        case .subscribeFromV1Paywall:
            E2ETestFlowView.SubscribeFromV1Paywall()
        case .subscribeFromV2Paywall:
            E2ETestFlowView.SubscribeFromV2Paywall()
        case .openWorkflow:
            E2ETestFlowView.OpenWorkflow()
        case .openNoPaywall:
            E2ETestFlowView.OpenNoPaywall()
        case .openWorkflowPresented:
            E2ETestFlowView.OpenWorkflowPresented()
        }
    }
}

enum E2ETestFlowView {}
