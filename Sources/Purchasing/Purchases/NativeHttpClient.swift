import Foundation
import PurchasesCore

/// PoC: Swift implementation of the Rust `HttpClient` foreign trait.
/// Rust calls `fetch(url:)` on this object and awaits the result.
class NativeHttpClient: HttpClient {

    func fetch(url: String) async throws -> String {
        guard let requestUrl = URL(string: url) else {
            throw HttpError.RequestFailed(reason: "Invalid URL: \(url)")
        }
        let (data, _) = try await URLSession.shared.data(from: requestUrl)
        guard let body = String(data: data, encoding: .utf8) else {
            throw HttpError.RequestFailed(reason: "Response is not valid UTF-8")
        }
        return body
    }

}
