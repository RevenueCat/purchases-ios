import SwiftUI
@testable import RevenueCat
#if DEBUG && targetEnvironment(simulator)
import StoreKit
import StoreKitTest
#endif

@main
struct RcMaestroApp: App {

    #if DEBUG && targetEnvironment(simulator)
    private let storeKitTestSession: SKTestSession?
    #endif

    init() {
        #if DEBUG && targetEnvironment(simulator)
        if UserDefaults.standard.string(forKey: "maestro_store") == "app_store" {
            do {
                let session = try SKTestSession(configurationFileNamed: "app787ddb07e6")
                session.resetToDefaultState()
                session.clearTransactions()
                session.disableDialogs = false
                self.storeKitTestSession = session
            } catch {
                fatalError("Unable to initialize Maestro StoreKit configuration: \(error)")
            }
        } else {
            self.storeKitTestSession = nil
        }
        if Self.isStoreKitWarmup {
            return
        }
        #endif

        Purchases.logLevel = .verbose
        Purchases.proxyURL = Constants.proxyURL.flatMap { URL(string: $0) }

        // Set API base URL if provided (used in E2E tests)
        if let apiBaseURL = Constants.apiBaseURL {
            SystemInfo.apiBaseURL = apiBaseURL
        }

        let forceServerErrorStrategy = Constants.forceServerErrorStrategy
        var configuration = Configuration.builder(withAPIKey: Constants.apiKey)
            .with(appUserID: Constants.appUserID)
            .with(preferredUILocaleOverride: Constants.preferredUILocale)
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
        if Self.usesInjectedPurchaseFailure {
            configuration = configuration.with(
                purchasesAreCompletedBy: .myApp,
                storeKitVersion: .default
            )
        }
        Purchases.configure(with: configuration.build())
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG && targetEnvironment(simulator)
            if Self.isStoreKitWarmup {
                StoreKitWarmupView()
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
    }

    @ViewBuilder
    private var appContent: some View {
        switch e2eTestFlow {
        case .some(let flow):
            flow.view
        case nil:
            ContentView()
        }
    }

    #if DEBUG && targetEnvironment(simulator)
    private static var isStoreKitWarmup: Bool {
        UserDefaults.standard.string(forKey: "maestro_store") == "app_store" &&
            UserDefaults.standard.bool(forKey: "maestro_storekit_warmup")
    }
    #endif

    private static var usesInjectedPurchaseFailure: Bool {
        guard let flow = UserDefaults.standard.string(forKey: "e2e_test_flow") else { return false }
        return flow == E2ETestFlow.checkpointPurchaseFailure.rawValue ||
            flow == E2ETestFlow.checkpointPurchaseFailureCustomErrorPresenter.rawValue
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

#if DEBUG && targetEnvironment(simulator)
private struct StoreKitWarmupView: View {
    @State private var status = "Connecting to StoreKit"

    var body: some View {
        Text(status)
            .task {
                do {
                    // Complete a StoreKit request before Maestro starts the real test process.
                    // The first process can return no products; the next launch must load the fixtures.
                    _ = try await Product.products(for: ["pro_monthly_subscription"])
                    status = "StoreKit warmup complete"
                } catch {
                    status = "StoreKit warmup failed: \(error.localizedDescription)"
                }
            }
    }
}
#endif

enum E2ETestFlow: String {
    case subscribeFromV1Paywall = "subscribe_from_v1_paywall"
    case subscribeFromV2Paywall = "subscribe_from_v2_paywall"
    case openWorkflow = "open_workflow"
    case openNoPaywall = "open_no_paywall"
    case openWorkflowPresented = "open_workflow_presented"
    case openWorkflowUIKit = "open_workflow_uikit"
    case openDefaultPackageVisibility = "open_default_package_visibility"
    case openDeveloperProvidedOffering = "open_developer_provided_offering"
    case checkpointInvalidIdentifier = "checkpoint_invalid_identifier"
    case checkpointInvalidIdentifierCustomErrorPresenter = "checkpoint_invalid_identifier_custom_error_presenter"
    case checkpointResolutionFailure = "checkpoint_resolution_failure"
    case checkpointResolutionFailureCustomErrorPresenter = "checkpoint_resolution_failure_custom_error_presenter"
    case checkpointConfigurationUnavailable = "checkpoint_configuration_unavailable"
    case checkpointConfigurationUnavailableCustomErrorPresenter =
        "checkpoint_configuration_unavailable_custom_error_presenter"
    case checkpointInitialScreenFailure = "checkpoint_initial_screen_failure"
    case checkpointInitialScreenFailureCustomErrorPresenter =
        "checkpoint_initial_screen_failure_custom_error_presenter"
    case checkpointSecondScreenFailure = "checkpoint_second_screen_failure"
    case checkpointSecondScreenFailureCustomErrorPresenter = "checkpoint_second_screen_failure_custom_error_presenter"
    case checkpointPurchaseFailure = "checkpoint_purchase_failure"
    case checkpointPurchaseFailureCustomErrorPresenter = "checkpoint_purchase_failure_custom_error_presenter"
    case checkpointResultSyncFailure = "checkpoint_result_sync_failure"
    case checkpointResultSyncFailureCustomErrorPresenter = "checkpoint_result_sync_failure_custom_error_presenter"
    case checkpointSuccessfulWorkflow = "checkpoint_successful_workflow"
    case checkpointNoMatch = "checkpoint_no_match"
    case checkpointInitialScreenFailureJapanese = "checkpoint_initial_screen_failure_japanese"
    case checkpointSecondScreenFailureSpanish = "checkpoint_second_screen_failure_spanish"
    case checkpointPublished = "checkpoint_published"

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
        case .openDeveloperProvidedOffering:
            E2ETestFlowView.OpenDeveloperProvidedOffering()
        case .checkpointInvalidIdentifier:
            E2ETestFlowView.CheckpointInvalidIdentifier()
        case .checkpointInvalidIdentifierCustomErrorPresenter:
            E2ETestFlowView.CheckpointInvalidIdentifierCustomErrorPresenter()
        case .checkpointResolutionFailure:
            E2ETestFlowView.CheckpointResolutionFailure()
        case .checkpointResolutionFailureCustomErrorPresenter:
            E2ETestFlowView.CheckpointResolutionFailureCustomErrorPresenter()
        case .checkpointConfigurationUnavailable:
            E2ETestFlowView.CheckpointConfigurationUnavailable()
        case .checkpointConfigurationUnavailableCustomErrorPresenter:
            E2ETestFlowView.CheckpointConfigurationUnavailableCustomErrorPresenter()
        case .checkpointInitialScreenFailure:
            E2ETestFlowView.CheckpointInitialScreenFailure()
        case .checkpointInitialScreenFailureCustomErrorPresenter:
            E2ETestFlowView.CheckpointInitialScreenFailureCustomErrorPresenter()
        case .checkpointSecondScreenFailure:
            E2ETestFlowView.CheckpointSecondScreenFailure()
        case .checkpointSecondScreenFailureCustomErrorPresenter:
            E2ETestFlowView.CheckpointSecondScreenFailureCustomErrorPresenter()
        case .checkpointPurchaseFailure:
            E2ETestFlowView.CheckpointPurchaseFailure()
        case .checkpointPurchaseFailureCustomErrorPresenter:
            E2ETestFlowView.CheckpointPurchaseFailureCustomErrorPresenter()
        case .checkpointResultSyncFailure:
            E2ETestFlowView.CheckpointResultSyncFailure()
        case .checkpointResultSyncFailureCustomErrorPresenter:
            E2ETestFlowView.CheckpointResultSyncFailureCustomErrorPresenter()
        case .checkpointSuccessfulWorkflow:
            E2ETestFlowView.CheckpointSuccessfulWorkflow()
        case .checkpointNoMatch:
            E2ETestFlowView.CheckpointNoMatch()
        case .checkpointInitialScreenFailureJapanese:
            E2ETestFlowView.CheckpointInitialScreenFailureJapanese()
        case .checkpointSecondScreenFailureSpanish:
            E2ETestFlowView.CheckpointSecondScreenFailureSpanish()
        case .checkpointPublished:
            E2ETestFlowView.CheckpointPublished()
        }
    }
}

enum E2ETestFlowView {}
