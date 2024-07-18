import RevenueCat

/// Typealias for handler for Customer center actions
public typealias CustomerCenterActionHandler = @MainActor @Sendable (CustomerCenterAction) -> Void

/// Represents an event the customer may perform during the Customer Center flow
public enum CustomerCenterAction {
    /// Purchase of a promotional offer is completed.
    case purchaseCompleted(_ customerInfo: CustomerInfo)
    /// Starting the restoration process
    case restoreStarted
    /// Restore errored out
    case restoreFailed(_ error: Error)
    /// Restore completed successfully
    case restoreCompleted(_ customerInfo: CustomerInfo)
    /// Going to display manage subscription page, whether for cancellation or changing plans.
    case showingManageSubscriptions
    /// Starting refund request process
    case refundRequestStarted(_ productId: String)
    /// Refund request process finished, with result provided.
    case refundRequestCompleted(_ refundRequestStatus: RefundRequestStatus)
}
