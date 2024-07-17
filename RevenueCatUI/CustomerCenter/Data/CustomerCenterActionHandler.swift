import Foundation
import RevenueCat

/// Allows to be notified of certain events the customer may perform during the Customer Center flow
public protocol CustomerCenterActionHandler {

    /// This will be called after a purchase of a promotional offer is completed.
    func onPurchaseCompleted(_ customerInfo: CustomerInfo)

    /// This will be called right before starting the restoration process
    func onRestoreStarted()

    /// This will be called after a restore errors out
    func onRestoreFailed(_ error: Error)

    /// This will be called after a successful restoration process
    func onRestoreCompleted(_ customerInfo: CustomerInfo)

    /// This will be called right before displaying the manage subscription page,
    /// which may happen for cancellations or changing plans
    func onShowManageSubscriptions()

    /// This will be called right before starting the refund request flow
    func onRefundRequestStarted(_ productId: String)

    /// This will be called right after the refund request flow, indicating the result of said flow
    func onRefundRequestCompleted(_ refundRequestStatus: RefundRequestStatus)

}

// swiftlint:disable missing_docs

public extension CustomerCenterActionHandler {

    func onPurchaseCompleted(_ customerInfo: CustomerInfo) {}
    func onRestoreStarted() {}
    func onRestoreFailed(_ error: Error) {}
    func onRestoreCompleted(_ customerInfo: CustomerInfo) {}
    func onShowManageSubscriptions() {}
    func onRefundRequestStarted(_ productId: String) {}
    func onRefundRequestCompleted(_ refundRequestStatus: RefundRequestStatus) {}

}

// swiftlint:enable missing_docs
