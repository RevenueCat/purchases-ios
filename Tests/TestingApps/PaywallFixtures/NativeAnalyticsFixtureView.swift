//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

#if DEBUG

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI

/// Records the real workflow events while UI tests tap either authored or native controls.
struct NativeAnalyticsFixtureView: View {
    @StateObject private var recorder = NativeAnalyticsRecorder()
    @State private var presented = true

    private let context = NativeNavigationFixture.makeContext(
        native: ProcessInfo.processInfo.environment["PAYWALL_ANALYTICS"] == "native",
        rootBack: ProcessInfo.processInfo.environment["PAYWALL_ANALYTICS_ROOT_BACK"] == "true",
        analytics: true
    )

    private var paywall: PaywallView {
        var configuration = PaywallViewConfiguration(
            offering: self.context.initialOffering,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: self.recorder.purchaseHandler
        )
        configuration.injectedWorkflowContext = self.context
        return PaywallView(configuration: configuration)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if self.presented {
                    self.paywall
                        .onRequestedDismissal { self.presented = false }
                        .navigationTitle("Analytics paywall")
                        // Keep the header button's XCTest tap point below the caller's navigation bar.
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Paywall dismissed")
                }
                Button("Capture analytics") {
                    Task { await self.recorder.capture() }
                }
                Text("Analytics captured")
                    .accessibilityIdentifier("analytics-result")
                    .accessibilityValue(self.recorder.result)
            }
        }
    }
}

@MainActor
private final class NativeAnalyticsRecorder: ObservableObject {
    @Published private(set) var result = ""
    let purchaseHandler: PurchaseHandler
    private let paywallEvents = Atomic<[PaywallEvent]>([])
    private let workflowEvents = Atomic<[WorkflowEvent]>([])
    private let dispatcher = PaywallEventTrackerTestDispatcher.value

    init() {
        let paywallEvents = self.paywallEvents
        let workflowEvents = self.workflowEvents
        let purchases = MockPurchases { _, _, _ in
            (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: true)
        } restorePurchases: {
            TestData.customerInfo
        } trackEvent: { event in
            paywallEvents.modify { $0.append(event) }
        } customerInfo: {
            TestData.customerInfo
        }
        purchases.trackWorkflowEventBlock = { event in workflowEvents.modify { $0.append(event) } }
        self.purchaseHandler = PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases, eventDispatcher: self.dispatcher)
        )
    }

    func capture() async {
        // The UI test requests a snapshot only after the destination/dismissed UI appears.
        // Drain the ordered dispatcher so event counts include lifecycle work already submitted.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.dispatcher { continuation.resume() }
        }
        let report = Report(
            paywall: self.paywallEvents.value.map(PaywallRecord.init),
            workflow: self.workflowEvents.value.map(WorkflowRecord.init)
        )
        do {
            self.result = String(decoding: try JSONEncoder().encode(report), as: UTF8.self)
        } catch {
            self.result = "Encoding failed: \(error)"
        }
    }

    private struct Report: Encodable {
        let paywall: [PaywallRecord]
        let workflow: [WorkflowRecord]
    }

    // Creation IDs and timestamps are intentionally omitted. All event payload fields are retained.
    private struct PaywallRecord: Encodable {
        let kind: String
        let data: PaywallEvent.Data
        let interaction: PaywallEvent.ComponentInteractionData?

        init(_ event: PaywallEvent) {
            switch event {
            case .impression: self.kind = "impression"
            case .componentInteraction: self.kind = "interaction"
            case .close: self.kind = "close"
            default: self.kind = "unexpected"
            }
            self.data = event.data
            self.interaction = event.componentInteractionData
        }
    }

    private struct WorkflowRecord: Encodable {
        let kind: String
        let data: WorkflowEvent.Data

        init(_ event: WorkflowEvent) {
            switch event {
            case .stepStarted: self.kind = "started"
            case .stepCompleted: self.kind = "completed"
            case .close: self.kind = "close"
            }
            self.data = event.data
        }
    }
}

#endif
