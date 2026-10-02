//
//  WorkflowRows.swift
//  PaywallsTester
//
//  Created by RevenueCat.
//

// Reads internal SDK methods, so it's Debug-only.
#if DEBUG && !os(tvOS)

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

/// A workflow synced through remote config, listed by id so workflows that claim no offering can be opened too.
struct WorkflowRow: Identifiable {

    let listing: WorkflowListing
    let name: String?
    let error: String?
    /// Offerings this flow's screens use, claimed or not.
    let offeringIdentifiers: Set<String>

    var id: String { self.listing.workflowId }

    var subtitle: String {
        if let error { return error }
        return self.listing.offeringIdentifier.map { "Offering: \($0)" } ?? "No claimed offering"
    }

    var claimedOfferingIdentifier: String? { self.listing.offeringIdentifier }

    func uses(_ offeringIdentifier: String) -> Bool {
        return self.listing.offeringIdentifier == offeringIdentifier
            || self.offeringIdentifiers.contains(offeringIdentifier)
    }

    func matches(_ searchText: String) -> Bool {
        return [self.id, self.name, self.listing.offeringIdentifier]
            .compactMap { $0 }
            .contains { $0.localizedCaseInsensitiveContains(searchText) }
    }

    static func loadAll() async -> [WorkflowRow] {
        let listings = await Purchases.shared.workflowListings()

        return await withTaskGroup(of: WorkflowRow.self) { group in
            for listing in listings {
                group.addTask {
                    do {
                        let result = try await Purchases.shared.workflow(withIdentifier: listing.workflowId)
                        return .init(
                            listing: listing,
                            name: result.workflow.displayName,
                            error: nil,
                            offeringIdentifiers: Set(result.workflow.screens.values.compactMap(\.offeringIdentifier))
                        )
                    } catch {
                        return .init(
                            listing: listing,
                            name: nil,
                            error: error.localizedDescription,
                            offeringIdentifiers: []
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
        async let result = Purchases.shared.workflow(withIdentifier: workflowId)
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

#endif
