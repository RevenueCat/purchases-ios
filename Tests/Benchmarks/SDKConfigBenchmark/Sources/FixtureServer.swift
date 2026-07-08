import Foundation

/// Routes simulated requests to deterministic fixture responses.
///
/// Routing is host-agnostic (path-suffix based) so the SDK's fallback hosts resolve to the
/// same fixtures as the primary host. Warm paths are supported the same way production is:
/// offerings replies 304 to a matching `X-RevenueCat-ETag`, config replies 204 to a matching
/// manifest token in the POST body. `killSwitchConfig` makes the config endpoint return a 4xx,
/// which trips `RemoteConfigManager`'s session kill switch.
final class FixtureServer {

    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    static let offeringsETag = "benchmark-offerings-v1"

    private let factory: BenchmarkPayloadFactory
    private let killSwitchConfig: Bool

    init(factory: BenchmarkPayloadFactory, killSwitchConfig: Bool = false) {
        self.factory = factory
        self.killSwitchConfig = killSwitchConfig
    }

    func response(for request: URLRequest, bodyData: Data?) -> Response {
        guard let url = request.url else {
            return Self.notFound()
        }
        let path = url.path

        if path.hasSuffix("/offerings"), path.contains("/subscribers/") || path.hasSuffix("/v1/offerings") {
            return self.offeringsResponse(for: request)
        }

        if path.hasSuffix("/config/app") {
            return self.configResponse(bodyData: bodyData)
        }

        if let blobRange = path.range(of: "/blobs/") {
            let ref = String(path[blobRange.upperBound...])
            return self.blobResponse(forRef: ref)
        }

        return Self.notFound()
    }

}

private extension FixtureServer {

    func offeringsResponse(for request: URLRequest) -> Response {
        let requestETag = request.value(forHTTPHeaderField: "X-RevenueCat-ETag")
        if requestETag == Self.offeringsETag {
            return Response(
                statusCode: 304,
                headers: self.jsonHeaders(eTag: Self.offeringsETag),
                body: Data()
            )
        }
        return Response(
            statusCode: 200,
            headers: self.jsonHeaders(eTag: Self.offeringsETag),
            body: self.factory.offeringsData
        )
    }

    func configResponse(bodyData: Data?) -> Response {
        if self.killSwitchConfig {
            let errorBody = Data(#"{"code": 7000, "message": "benchmark kill switch"}"#.utf8)
            return Response(statusCode: 400, headers: self.jsonHeaders(eTag: nil), body: errorBody)
        }

        if let bodyData,
           let body = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           body["manifest"] as? String == self.factory.configManifest {
            return Response(statusCode: 204, headers: [:], body: Data())
        }

        return Response(
            statusCode: 200,
            headers: ["Content-Type": "application/octet-stream"],
            body: self.factory.configContainerData
        )
    }

    func blobResponse(forRef ref: String) -> Response {
        guard let blob = self.factory.blobData(forRef: ref) else {
            return Self.notFound()
        }
        return Response(
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: blob
        )
    }

    func jsonHeaders(eTag: String?) -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let eTag {
            headers["X-RevenueCat-ETag"] = eTag
        }
        return headers
    }

    static func notFound() -> Response {
        return Response(
            statusCode: 404,
            headers: ["Content-Type": "application/json"],
            body: Data(#"{"code": 7259, "message": "benchmark fixture not found"}"#.utf8)
        )
    }

}
