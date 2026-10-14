//
//  WorkflowRows.swift
//  PaywallsTester
//
//  Created by RevenueCat.
//

// Reads internal SDK methods, so it's Debug-only.
#if DEBUG && !os(tvOS)

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @_spi(InviteOnlyCheckpointsApi) @testable import RevenueCatUI
import SwiftUI

/// A workflow synced through remote config, listed by id so workflows that claim no offering can be opened too.
struct WorkflowRow: Identifiable {

    let id: String
    /// Offerings that route to this flow, resolved the same way the SDK resolves an offering entry point.
    let claimedOfferingIdentifiers: Set<String>
    let name: String?
    let error: String?
    /// Offerings this flow's steps use, claimed or not.
    let offeringIdentifiers: Set<String>
    /// Set when the first step is an offering step: the flow shows no UI and only returns this offering.
    let uiLessOfferingIdentifier: String?

    var subtitle: String {
        if let error { return error }
        if !self.claimedOfferingIdentifiers.isEmpty {
            return "Offering: \(self.claimedOfferingIdentifiers.sorted().joined(separator: ", "))"
        }
        // Not attached to an offering, so show what its screens use instead.
        guard !self.offeringIdentifiers.isEmpty else { return "No offering" }
        return "Uses: \(self.offeringIdentifiers.sorted().joined(separator: ", "))"
    }

    func uses(_ offeringIdentifier: String) -> Bool {
        return self.claimedOfferingIdentifiers.contains(offeringIdentifier)
            || self.offeringIdentifiers.contains(offeringIdentifier)
    }

    func matches(_ searchText: String) -> Bool {
        return ([self.id, self.name].compactMap { $0 } + self.claimedOfferingIdentifiers)
            .contains { $0.localizedCaseInsensitiveContains(searchText) }
    }

    static func loadAll(offerings: [Offering]) async -> [WorkflowRow] {
        let workflowIds = await Purchases.shared.workflowIds()
        var claims: [String: Set<String>] = [:]
        for offering in offerings {
            if let workflowId = await Purchases.shared.workflowId(forOfferingIdentifier: offering.identifier) {
                claims[workflowId, default: []].insert(offering.identifier)
            }
        }

        return await withTaskGroup(of: WorkflowRow.self) { group in
            for workflowId in workflowIds {
                let claimed = claims[workflowId] ?? []
                group.addTask {
                    do {
                        let result = try await Purchases.shared.workflow(forWorkflowIdentifier: workflowId)
                        let workflow = result.workflow
                        let initialStep = workflow.steps[workflow.initialStepId]
                        // Same rule as checkpoints: an offering step must be the flow's only step.
                        let isUILess = initialStep?.isOfferingStep == true
                        let uiLessOfferingIdentifier = workflow.steps.count == 1 ? initialStep?.offeringIdentifier : nil
                        return .init(
                            id: workflowId,
                            claimedOfferingIdentifiers: claimed,
                            name: workflow.displayName,
                            error: isUILess && uiLessOfferingIdentifier == nil
                                ? "Not servable: an offering step must be the only step and name an offering."
                                : nil,
                            offeringIdentifiers: Set(
                                result.workflow.steps.values.compactMap { result.workflow.offeringIdentifier(for: $0) }
                            ),
                            uiLessOfferingIdentifier: isUILess ? uiLessOfferingIdentifier : nil
                        )
                    } catch {
                        return .init(
                            id: workflowId,
                            claimedOfferingIdentifiers: claimed,
                            name: nil,
                            error: error.localizedDescription,
                            offeringIdentifiers: [],
                            uiLessOfferingIdentifier: nil
                        )
                    }
                }
            }

            var rows: [WorkflowRow] = []
            for await row in group {
                rows.append(row)
            }
            return rows.sorted { ($0.name ?? $0.id).localizedCaseInsensitiveCompare($1.name ?? $1.id) == .orderedAscending }
        }
    }

}

/// A workflow ready to render, built the same way checkpoints present one.
struct PresentedWorkflow: Identifiable {

    let id: String
    let context: WorkflowContext

    static func load(workflowId: String) async throws -> PresentedWorkflow {
        async let result = Purchases.shared.workflow(forWorkflowIdentifier: workflowId)
        let offerings = try await Purchases.shared.offerings()
        let workflow = try await result

        return .init(
            id: workflowId,
            context: try WorkflowPreview.makeContext(
                workflow: workflow.workflow,
                offerings: offerings,
                uiConfig: workflow.uiConfig,
                workflowBlobRef: workflow.workflowBlobRef
            )
        )
    }

}

#if canImport(UIKit) && !os(watchOS)
/// Shows a UI-less flow's offering with the presenter the SDK uses when a checkpoint returns an offering:
/// the offering's paywall, or the fallback paywall.
@MainActor
enum UILessFlowPresenter {

    private static let presenter = DefaultPaywallPresenter()
    // Checkpoints always pass an error presenter, so purchase and restore errors are shown.
    private static let errorPresenter = DefaultErrorPresenter()

    static func present(_ offering: Offering, customVariables: [String: CustomVariableValue]) {
        self.presenter.present(
            params: .init(
                checkpointIdentifier: "paywalls_tester",
                customVariables: customVariables,
                offering: offering,
                errorPresentationHandler: { params, completion in
                    self.errorPresenter.present(params: params, completion: completion)
                }
            )
        ) { _ in }
    }

}
#endif

#endif
