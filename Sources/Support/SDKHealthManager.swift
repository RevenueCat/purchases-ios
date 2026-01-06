import Foundation

final class SDKHealthManager: Sendable {
    private let backend: Backend
    private let identityManager: IdentityManager
    private let paymentAuthorizationProvider: PaymentAuthorizationProvider

    init(
        backend: Backend,
        identityManager: IdentityManager,
        paymentAuthorizationProvider: PaymentAuthorizationProvider = .storeKit
    ) {
        self.backend = backend
        self.identityManager = identityManager
        self.paymentAuthorizationProvider = paymentAuthorizationProvider
    }

    #if DEBUG
    func healthReport() async -> PurchasesDiagnostics.SDKHealthReport {
        do {
            if !paymentAuthorizationProvider.isAuthorized() {
                return .init(status: .unhealthy(.notAuthorizedToMakePayments))
            }
            let appUserID = self.identityManager.currentAppUserID
            return try await self.backend.healthReportRequest(appUserID: appUserID).validate()
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
    #endif

    #if DEBUG && !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func logSDKHealthReportOutcome() async {
        let report = await healthReport()
        switch report.status {
        case let .unhealthy(error):
            switch error {
            case .unknown: break
            default: Logger.error(HealthReportLogMessage.unhealthy(error: error, report: report))
            }
        case let .healthy(warnings):
            if warnings.isEmpty {
                Logger.info(HealthReportLogMessage.healthy(report: report))
            } else {
                Logger.warn(HealthReportLogMessage.healthyWithWarnings(warnings: warnings, report: report))
            }
        }
    }
    #endif
}

#if DEBUG && !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
private enum HealthReportLogMessage: LogMessage {
    case unhealthy(error: PurchasesDiagnostics.SDKHealthError, report: PurchasesDiagnostics.SDKHealthReport)
    case healthy(report: PurchasesDiagnostics.SDKHealthReport)
    case healthyWithWarnings(
        warnings: [PurchasesDiagnostics.SDKHealthError],
        report: PurchasesDiagnostics.SDKHealthReport
    )

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

    private func buildUnhealthyMessage(
        error: PurchasesDiagnostics.SDKHealthError,
        report: PurchasesDiagnostics.SDKHealthReport
    ) -> String {
        var message = "RevenueCat SDK Configuration is not valid\n"
        message += "\n\(error.localizedDescription)\n"

        let actionURL: String? = {
            guard let projectId = report.projectId, let appId = report.appId else { return nil }

            switch error {
            case .invalidBundleId:
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
        var message = "✅ RevenueCat SDK is configured correctly\n"

        message += buildProductsSection(report: report)
        message += buildOfferingsSection(report: report)

        return message
    }

    private func buildHealthyWithWarningsMessage(
        warnings: [PurchasesDiagnostics.SDKHealthError],
        report: PurchasesDiagnostics.SDKHealthReport
    ) -> String {
        if report.products.allSatisfy({ $0.status == .couldNotCheck }) {
            var message = """
            We could not validate your SDK's configuration and check your product statuses in App Store Connect.\n
            """

            if let description = report.products.first?.description {
                message += "\nError: \(description)\n"
            }

            message += """
            \nIf you want to check if your SDK is configured correctly, please check your App Store Connect \
            credentials in RevenueCat, make sure your App Store Connect App exists and try again:
            """

            if let projectId = report.projectId, let appId = report.appId {
                let url = "https://app.revenuecat.com/projects/\(projectId)/apps/\(appId)#scroll=app-store-connect-api"
                message += "\n\n\(url)"
            }

            return message
        }

        var message = "RevenueCat SDK is configured correctly, but contains some issues you might want to address\n"

        message += "\nWarnings:\n"
        for warning in warnings {
            message += "  • \(warning.localizedDescription)\n"
        }

        message += buildProductsSection(report: report)
        message += buildOfferingsSection(report: report)

        return message
    }

    private func buildProductsSection(report: PurchasesDiagnostics.SDKHealthReport) -> String {
        let productsWithIssues = report.products.filter { $0.status != .valid }
        guard !productsWithIssues.isEmpty else { return "" }

        var section = "\nProduct Issues:\n"
        for product in productsWithIssues {
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
        let offeringsWithIssues = report.offerings.filter { $0.status != .passed }
        guard !offeringsWithIssues.isEmpty else { return "" }

        var section = "\nOffering Issues:\n"
        for offering in offeringsWithIssues {
            let statusIcon = offeringStatusIcon(offering.status)
            section += "  \(statusIcon) \(offering.identifier)\n"
            let packagesWithIssues = offering.packages.filter { $0.status != .valid }
            for package in packagesWithIssues {
                let packageStatusIcon = productStatusIcon(package.status)
                let packageInfo = "\(packageStatusIcon) \(package.identifier) (\(package.productIdentifier))"
                section += "    \(packageInfo): \(package.description)\n"
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
