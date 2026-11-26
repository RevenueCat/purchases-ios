import CryptoKit
import os
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

/// Supports the workflow performance benchmark in AutomatedSDKTestsApp.
/// Loads workflow content before capture and records its configuration and display settings for comparison.
/// Marks workflow presentation in Instruments.
enum WorkflowProfile {

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: "workflow_profile") }

    private static let log = OSLog(subsystem: "com.revenuecat.workflow-profile", category: .pointsOfInterest)

    static func present() {
        guard Self.isEnabled else { return }
        os_signpost(.event, log: Self.log, name: "Present workflow")
    }

    @MainActor
    static func prepare(
        offering: Offering,
        offerings: Offerings
    ) async throws -> @MainActor () throws -> WorkflowContext {
        let result = try await Purchases.shared.workflow(forOfferingIdentifier: offering.identifier)
        guard let blobRef = result.workflowBlobRef else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let config = try encoder.encode(result.uiConfig)
        let packages = offering.availablePackages.map { package in
            ["package": package.identifier, "product": package.storeProduct.productIdentifier,
             "price": package.storeProduct.price.description, "price_string": package.localizedPriceString]
        }
        let metadata: [String: Any] = [
            "offering": offering.identifier, "workflow_id": result.workflow.id, "blob_ref": blobRef,
            "ui_config_sha256": SHA256.hash(data: config).map { String(format: "%02x", $0) }.joined(),
            "packages": packages, "locale": "en_US", "appearance": "light", "dynamic_type": "large",
            "reduce_motion": UIAccessibility.isReduceMotionEnabled,
            "screen_width": UIScreen.main.bounds.width, "screen_height": UIScreen.main.bounds.height,
            "screen_scale": UIScreen.main.scale
        ]
        guard let directory = DirectoryHelper.baseUrl(for: .cache, inAppSpecificDirectory: false) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: metadata, options: [.sortedKeys])
            .write(to: directory.appendingPathComponent("workflow-profile.json"), options: .atomic)
        return {
            os_signpost(.begin, log: Self.log, name: "Build workflow context")
            defer { os_signpost(.end, log: Self.log, name: "Build workflow context") }
            return try WorkflowPreview.makeContext(
                workflow: result.workflow, offerings: offerings, uiConfig: result.uiConfig,
                workflowBlobRef: blobRef
            )
        }
    }

}
