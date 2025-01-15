//
//  PurchaseDetailItem.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 15/1/25.
//

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum PurchaseDetailItem: Identifiable {
    case productName(String?)
    case purchaseDate(String)
    case status(String)

    case nextRenewalDate(String)
    case expiresDate(String)
    case unsubscribeDetectedAt(String)
    case billingIssuesDetectedAt(String)
    case gracePeriodExpiresDate(String)
    case periodType(String)
    case refundedAtDate(String)

    // DEBUG only
    case store(String)
    case productID(String)
    case sandbox(Bool)
    case transactionID(String)

    var label: String {
        switch self {
        case .productName: return String(localized: "Product name")
        case .purchaseDate:  return String(localized: "Original Download Date")
        case .status: return String(localized: "Status")
        case .nextRenewalDate: return String(localized: "Next Renewal")
        case .expiresDate: return String(localized: "Expires")
        case .unsubscribeDetectedAt: return String(localized: "Unsubscribed At")
        case .billingIssuesDetectedAt: return String(localized: "Billing Issue Detected At")
        case .gracePeriodExpiresDate: return String(localized: "Grace Period Expires At")
        case .periodType: return String(localized: "Period Type")
        case .refundedAtDate: return String(localized: "Refunded At")
        case .store: return String(localized: "Store")
        case .productID: return String(localized: "Product ID")
        case .sandbox: return String(localized: "Sandbox")
        case .transactionID: return String(localized: "TransactionID")
        }
    }

    var content: String {
        switch self {
        case let .productName(name): return name ?? "-"

        case .purchaseDate(let value),
                .expiresDate(let value),
                .nextRenewalDate(let value),
                .unsubscribeDetectedAt(let value),
                .billingIssuesDetectedAt(let value),
                .gracePeriodExpiresDate(let value),
                .status(let value),
                .periodType(let value),
                .refundedAtDate(let value),
                .store(let value),
                .productID(let value),
                .transactionID(let value):
            return value

        case .sandbox(let value):
            return value ? "Yes" : "No"
        }
    }

    var isDebugOnly: Bool {
        switch self {
        case .store, .productID, .sandbox, .transactionID:
            return true
        default:
            return false
        }
    }

    var id: String {
        label
    }
}
