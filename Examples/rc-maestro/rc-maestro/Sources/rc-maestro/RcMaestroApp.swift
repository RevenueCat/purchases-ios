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

        let forceServerErrorStrategy = Constants.forceServerErrorStrategy
        Purchases.configure(
            with: .builder(withAPIKey: Constants.apiKey)
                .with(dangerousSettings: .init(
                    autoSyncPurchases: true,
                    internalSettings: DangerousSettings.Internal(
                        forceServerErrorStrategy: .init { request in
                            switch forceServerErrorStrategy {
                            case .never:
                                return .performRequest

                            case .primaryBackendDown:
                                // Remote config uses a separate request path whose primary URL is already
                                // the fallback backend, so it does not have a fallbackUrlIndex.
                                if let fallbackPath = request.httpRequest.path as? HTTPRequest.FallbackPath,
                                   case .remoteConfig = fallbackPath {
                                    return .performRequest
                                }
                                return request.fallbackUrlIndex == nil ? .defaultServerError : .performRequest

                            case .remoteConfigNetworkError:
                                // No network for /v1/config only; offerings still resolve so a paywall
                                // is presentable and can degrade to the classic paywall. The unreachable
                                // host makes the request fail with a transport error.
                                guard request.path.contains("config/") else { return .performRequest }
                                return .serverErrorURL(URL(string: "http://127.0.0.1:1")!)
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
        
        return E2ETestFlow(rawValue: string)
    }
}

enum E2ETestFlow: String {
    case subscribeFromV1Paywall = "subscribe_from_v1_paywall"
    case subscribeFromV2Paywall = "subscribe_from_v2_paywall"
    case openWorkflow = "open_workflow"
    case openNoPaywall = "open_no_paywall"
    case openWorkflowPresented = "open_workflow_presented"
    case openWorkflowUIKit = "open_workflow_uikit"
    case openDefaultPackageVisibility = "open_default_package_visibility"

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
        case .openWorkflowUIKit:
            E2ETestFlowView.OpenWorkflowUIKit()
        case .openDefaultPackageVisibility:
            E2ETestFlowView.OpenDefaultPackageVisibility()
        }
    }
}

enum E2ETestFlowView {}
