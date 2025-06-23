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

    private var canMakePayments: Bool {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
            return AppStore.canMakePayments
        } else {
            return SKPaymentQueue.canMakePayments()
        }
    }
}
#endif
