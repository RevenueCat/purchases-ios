//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
final class NativePaywallCloseCoordinator: ObservableObject {
    enum Role: Equatable { case back, close }

    struct CloseAction {
        let id: UUID
        let label: String
        let perform: () async throws -> Void
        var role: Role = .close
        var isWorkflowClose = false
        var pageID: UUID?
        var isEnabled = true
    }

    @Published private(set) var actions: [CloseAction] = []
    private var registrations: [CloseAction] = []
    private var callbacks: [UUID: () async throws -> Void] = [:]
    private var activePageID: UUID?

    func activatePage(_ pageID: UUID?) {
        guard self.activePageID != pageID else { return }
        self.activePageID = pageID
        self.updateActions()
    }

    private func updateActions() {
        self.actions = self.registrations.filter { $0.pageID == self.activePageID }
    }

    func register(
        id: UUID,
        label: String,
        role: Role = .close,
        isWorkflowClose: Bool = false,
        pageID: UUID? = nil,
        isEnabled: Bool = true,
        action: @escaping () async throws -> Void
    ) {
        self.callbacks[id] = action
        let value = CloseAction(
            id: id, label: label, perform: { [weak self] in try await self?.performAction(id: id) },
            role: role, isWorkflowClose: isWorkflowClose,
            pageID: pageID, isEnabled: isEnabled
        )
        if let index = self.registrations.firstIndex(where: { $0.id == id }) {
            guard self.registrations[index].role != role || self.registrations[index].label != label
                || self.registrations[index].isWorkflowClose != isWorkflowClose
                || self.registrations[index].pageID != pageID
                || self.registrations[index].isEnabled != isEnabled else { return }
            self.registrations[index] = value
        } else {
            self.registrations.append(value)
        }
        self.updateActions()
    }

    func refreshAction(id: UUID, action: @escaping () async throws -> Void) {
        guard self.callbacks[id] != nil else { return }
        self.callbacks[id] = action
    }

    func action(for role: Role) -> CloseAction? {
        if role == .close, let close = self.actions.first(where: { $0.role == .close && $0.isWorkflowClose }) {
            return close
        }
        return self.actions.first { $0.role == role }
    }

    func unregister(id: UUID) {
        guard self.registrations.contains(where: { $0.id == id }) else { return }
        self.registrations.removeAll { $0.id == id }
        self.callbacks[id] = nil
        self.updateActions()
    }

    func performAction(id: UUID) async throws {
        guard let action = self.actions.first(where: { $0.id == id }), action.isEnabled else { return }
        try await self.callbacks[id]?()
    }
}

#endif
