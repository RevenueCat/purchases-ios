//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Combine
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallPackageSelectionDetails: PaywallStateChange.Details {

    enum Source: Hashable, Sendable {
        case rootPackageRow(componentIdentity: PaywallComponentIdentity?)
        case sheetPackageRow(sheetComponentID: String, componentIdentity: PaywallComponentIdentity?)
        case sheetDismissal(sheetComponentID: String)
        case tabs
    }

    let source: Source

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallPackageSelectionCoordinator: ObservableObject {

    let scope: PaywallStateScope
    let store: PaywallStateStore
    let mutationHandler: PaywallStateMutationHandler?
    let packageContext: PackageContext
    let packagesByID: [String: Package]
    let defaultPackage: Package?
    let currentWorkflowSelectedPackage: () -> Package?

    private var cancellables: Set<AnyCancellable> = []
    private var pendingSheetDismissalRestorations: [String: Package?] = [:]
    private var pendingVariableContexts: [PendingSelection: PackageContext.VariableContext] = [:]

    init(
        scope: PaywallStateScope,
        store: PaywallStateStore,
        mutationHandler: PaywallStateMutationHandler?,
        packageContext: PackageContext,
        packages: [Package],
        defaultPackage: Package?,
        currentWorkflowSelectedPackage: @escaping () -> Package?
    ) {
        self.scope = scope
        self.store = store
        self.mutationHandler = mutationHandler
        self.packageContext = packageContext
        self.packagesByID = Dictionary(uniqueKeysWithValues: packages.map { ($0.identifier, $0) })
        self.defaultPackage = defaultPackage
        self.currentWorkflowSelectedPackage = currentWorkflowSelectedPackage

        self.store.resolvedEvents
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleCommittedEvent(event)
                }
            }
            .store(in: &self.cancellables)
    }

    func selectPackage(
        _ package: Package,
        sheetComponentID: String?,
        componentIdentity: PaywallComponentIdentity?,
        variableContext: PackageContext.VariableContext? = nil,
        source: PaywallPackageSelectionDetails.Source? = nil
    ) {
        if let sheetComponentID {
            self.selectSheetPackage(
                package,
                componentID: sheetComponentID,
                componentIdentity: componentIdentity,
                variableContext: variableContext,
                source: source
            )
        } else {
            self.selectRootPackage(
                package,
                componentIdentity: componentIdentity,
                variableContext: variableContext,
                source: source
            )
        }
    }

    func selectRootPackage(
        _ package: Package,
        componentIdentity: PaywallComponentIdentity? = nil,
        variableContext: PackageContext.VariableContext? = nil,
        source: PaywallPackageSelectionDetails.Source? = nil
    ) {
        self.requestPackageSelection(
            packageID: package.identifier,
            key: Self.rootKey(scope: self.scope),
            details: PaywallPackageSelectionDetails(
                source: source ?? .rootPackageRow(componentIdentity: componentIdentity)
            ),
            variableContext: variableContext
        )
    }

    func selectSheetPackage(
        _ package: Package,
        componentID: String,
        componentIdentity: PaywallComponentIdentity? = nil,
        variableContext: PackageContext.VariableContext? = nil,
        source: PaywallPackageSelectionDetails.Source? = nil
    ) {
        self.requestPackageSelection(
            packageID: package.identifier,
            key: Self.sheetKey(scope: self.scope, componentID: componentID),
            details: PaywallPackageSelectionDetails(source: source ?? .sheetPackageRow(
                sheetComponentID: componentID,
                componentIdentity: componentIdentity
            )),
            variableContext: variableContext
        )
    }

    func clearPackageSelection(
        sheetComponentID: String?,
        variableContext: PackageContext.VariableContext? = nil,
        source: PaywallPackageSelectionDetails.Source = .tabs
    ) {
        let key = sheetComponentID
            .map { Self.sheetKey(scope: self.scope, componentID: $0) }
            ?? Self.rootKey(scope: self.scope)

        self.requestPackageSelection(
            packageID: nil,
            key: key,
            details: PaywallPackageSelectionDetails(source: source),
            variableContext: variableContext
        )
    }

    func clearSheetSelection(componentID: String) {
        self.pendingSheetDismissalRestorations[componentID] =
            self.currentWorkflowSelectedPackage() ?? self.defaultPackage
        let sheetKey = Self.sheetKey(scope: self.scope, componentID: componentID)
        let sheetSelectionWasAlreadyEmpty = self.store.value(for: sheetKey) == nil
        self.store.request(
            .init(
                key: sheetKey,
                value: nil
            ),
            details: PaywallPackageSelectionDetails(source: .sheetDismissal(sheetComponentID: componentID)),
            mutationHandler: nil
        )
        if sheetSelectionWasAlreadyEmpty,
           let restoration = self.pendingSheetDismissalRestorations.removeValue(forKey: componentID) {
            self.updatePackageContext(package: restoration)
        }
    }

    private func requestPackageSelection(
        packageID: String?,
        key: PaywallStateKey,
        details: PaywallPackageSelectionDetails,
        variableContext: PackageContext.VariableContext?
    ) {
        if let variableContext, let packageID {
            self.pendingVariableContexts[.init(key: key, packageID: packageID)] = variableContext
        }
        self.store.request(
            .init(key: key, value: .packageID(packageID)),
            details: details,
            mutationHandler: self.mutationHandler
        )
    }

    private func handleCommittedEvent(_ event: PaywallStateChange.Event<PaywallStateChange.Committed>) {
        guard event.key.scope == self.scope else { return }

        if event.key == Self.rootKey(scope: self.scope) {
            self.updatePackageContext(packageID: event.newValue?.packageID, key: event.key)
        } else if let sheetComponentID = Self.sheetComponentID(from: event.key.field) {
            self.handleSheetEvent(event, sheetComponentID: sheetComponentID)
        }
    }

    private func handleSheetEvent(
        _ event: PaywallStateChange.Event<PaywallStateChange.Committed>,
        sheetComponentID: String
    ) {
        if let newValue = event.newValue {
            self.pendingSheetDismissalRestorations[sheetComponentID] = nil
            self.updatePackageContext(packageID: newValue.packageID, key: event.key)
        } else if let restoration = self.pendingSheetDismissalRestorations.removeValue(forKey: sheetComponentID) {
            self.updatePackageContext(package: restoration)
        } else {
            self.updatePackageContext(package: nil)
        }
    }

    private func updatePackageContext(packageID: String?, key: PaywallStateKey) {
        let variableContext = packageID.flatMap {
            self.pendingVariableContexts.removeValue(forKey: .init(key: key, packageID: $0))
        }
        self.pendingVariableContexts = self.pendingVariableContexts.filter { $0.key.key != key }
        self.updatePackageContext(
            package: packageID.flatMap { self.packagesByID[$0] },
            variableContext: variableContext
        )
    }

    private func updatePackageContext(
        package: Package?,
        variableContext: PackageContext.VariableContext? = nil
    ) {
        self.packageContext.update(
            package: package,
            variableContext: variableContext ?? self.packageContext.variableContext
        )
    }

    private static func rootKey(scope: PaywallStateScope) -> PaywallStateKey {
        .paywall(scope: scope, field: .rootSelectedPackageID)
    }

    private static func sheetKey(scope: PaywallStateScope, componentID: String) -> PaywallStateKey {
        .paywall(scope: scope, field: .sheetSelectedPackageID(componentID: componentID))
    }

    private static func sheetComponentID(from field: PaywallStateKey.Field) -> String? {
        let prefix = "paywall.sheet["
        let suffix = "].selected_package_id"
        let rawValue = field.rawValue

        guard rawValue.hasPrefix(prefix), rawValue.hasSuffix(suffix) else {
            return nil
        }

        return String(rawValue.dropFirst(prefix.count).dropLast(suffix.count))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PendingSelection: Hashable {
    let key: PaywallStateKey
    let packageID: String
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallPackageSelectionCoordinatorKey: EnvironmentKey {
    static let defaultValue: PaywallPackageSelectionCoordinator? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallPackageSelectionSheetComponentIDKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallPackageSelectionCoordinator: PaywallPackageSelectionCoordinator? {
        get { self[PaywallPackageSelectionCoordinatorKey.self] }
        set { self[PaywallPackageSelectionCoordinatorKey.self] = newValue }
    }

    var paywallPackageSelectionSheetComponentID: String? {
        get { self[PaywallPackageSelectionSheetComponentIDKey.self] }
        set { self[PaywallPackageSelectionSheetComponentIDKey.self] = newValue }
    }

}

#endif
