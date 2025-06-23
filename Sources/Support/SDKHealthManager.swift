#if DEBUG
import Foundation
import StoreKit

final class SDKHealthManager: Sendable {
    private let healthReportRequest: @Sendable () async throws -> HealthReport

    init(healthReportRequest: @Sendable @escaping () async throws -> HealthReport) {
        self.healthReportRequest = healthReportRequest
    }

    func healthReport() async -> PurchasesDiagnostics.SDKHealthReport {
        do {
            if !canMakePayments {
                return .init(status: .unhealthy(.notAuthorizedToMakePayments))
            }
            return try await self.healthReportRequest().validate()
        } catch let error as BackendError {
            if case .networkError(let networkError) = error,
               case .errorResponse(let response, _, _) = networkError, response.code == .invalidAPIKey {
                return .init(status: .unhealthy(.invalidAPIKey))
            }
            return .init(status: .unhealthy(.unknown(error)))
        } catch {
            return .init(status: .unhealthy(.unknown(error)))
        }
    }

    func logSDKHealthReportOutcome() async {
        let report = await healthReport()
        switch report.status {
        case let .unhealthy(error):
            Logger.error(HealthReportLogMessage.unhealthy(error: error, report: report))
        case let .healthy(warnings):
            if warnings.isEmpty {
                Logger.info(HealthReportLogMessage.healthy(report: report))
            } else {
                Logger.warn(HealthReportLogMessage.healthyWithWarnings(warnings: warnings, report: report))
            }
        }
    }

    private var canMakePayments: Bool {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
            return AppStore.canMakePayments
        } else {
            return SKPaymentQueue.canMakePayments()
        }
    }
}

private enum HealthReportLogMessage: LogMessage {
    case unhealthy(error: PurchasesDiagnostics.SDKHealthError, report: PurchasesDiagnostics.SDKHealthReport)
    case healthy(report: PurchasesDiagnostics.SDKHealthReport)
    case healthyWithWarnings(warnings: [PurchasesDiagnostics.SDKHealthError], report: PurchasesDiagnostics.SDKHealthReport)

    var description: String {
        switch self {
        case let .unhealthy(error, report):
            return buildUnhealthyMessage(error: error, report: report)
        case let .healthy(report):
            return buildHealthyMessage(report: report)
        case let .healthyWithWarnings(warnings, report):
            return buildHealthyWithWarningsMessage(warnings: warnings, report: report)
        }
    }

    var category: String { "health_report" }

    private func buildUnhealthyMessage(error: PurchasesDiagnostics.SDKHealthError, report: PurchasesDiagnostics.SDKHealthReport) -> String {
        var message = "SDK Configuration is not valid\n"
        message += "\n\(error.localizedDescription)\n"

        let actionURL: String? = {
            guard let projectId = report.projectId, let appId = report.appId else { return nil }

            switch error {
            case .invalidBundleId(let invalidBundleIdErrorPayload):
                return "https://app.revenuecat.com/projects/\(projectId)/apps/\(appId)"
            case .offeringConfiguration, .noOfferings:
                return "https://app.revenuecat.com/projects/\(projectId)/product-catalog/offerings"
            case .invalidProducts:
                return "https://app.revenuecat.com/projects/\(projectId)/product-catalog/products"
            default: return nil
            }
        }()

        if let actionURL {
            message += "\nPlease visit the RevenueCat website to resolve the issue: \(actionURL)\n"
        }

        message += buildProductsSection(report: report)
        message += buildOfferingsSection(report: report)
        
        return message
    }

    private func buildHealthyMessage(report: PurchasesDiagnostics.SDKHealthReport) -> String {
        var message = "SDK Configuration is Valid\n"
        
        message += buildProductsSection(report: report)
        message += buildOfferingsSection(report: report)
        
        return message
    }

    private func buildHealthyWithWarningsMessage(warnings: [PurchasesDiagnostics.SDKHealthError], report: PurchasesDiagnostics.SDKHealthReport) -> String {
        var message = "SDK is configured correctly, but contains some issues you might want to address\n"
        
        message += "\nWarnings:\n"
        for warning in warnings {
            message += "  • \(warning.localizedDescription)\n"
        }
        
        message += buildProductsSection(report: report)
        message += buildOfferingsSection(report: report)
        
        return message
    }

    private func buildProductsSection(report: PurchasesDiagnostics.SDKHealthReport) -> String {
        guard !report.products.isEmpty else { return "" }
        
        var section = "\nProducts Status:\n"
        for product in report.products {
            let statusIcon = productStatusIcon(product.status)
            section += "  \(statusIcon) \(product.identifier)"
            if let title = product.title {
                section += " (\(title))"
            }
            section += ": \(product.description)\n"
        }
        
        return section
    }

    private func buildOfferingsSection(report: PurchasesDiagnostics.SDKHealthReport) -> String {
        guard !report.offerings.isEmpty else { return "" }
        
        var section = "\nOfferings Status:\n"
        for offering in report.offerings {
            let statusIcon = offeringStatusIcon(offering.status)
            section += "  \(statusIcon) \(offering.identifier)\n"
            for package in offering.packages {
                let packageStatusIcon = productStatusIcon(package.status)
                section += "    \(packageStatusIcon) \(package.identifier) (\(package.productIdentifier)): \(package.description)\n"
            }
        }
        
        return section
    }

    private func productStatusIcon(_ status: PurchasesDiagnostics.ProductStatus) -> String {
        switch status {
        case .valid: return "✅"
        case .couldNotCheck: return "❓"
        case .notFound: return "❌"
        case .actionInProgress: return "⏳"
        case .needsAction: return "⚠️"
        case .unknown: return "❓"
        }
    }

    private func offeringStatusIcon(_ status: PurchasesDiagnostics.SDKHealthCheckStatus) -> String {
        switch status {
        case .passed: return "✅"
        case .failed: return "❌"
        case .warning: return "⚠️"
        }
    }
}
#endif
