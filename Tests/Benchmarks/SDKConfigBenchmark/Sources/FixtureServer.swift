import Foundation

/// Routes simulated requests to deterministic fixture responses.
///
/// Routing uses the shared `RequestKind` classifier, so the server, the metrics attribution,
/// and the warm-scenario validation can never disagree about what a request was. Warm paths
/// are supported the same way production is: offerings replies 304 to a matching
/// `X-RevenueCat-ETag`, config replies 204 to a matching manifest token in the POST body.
/// `killSwitchConfig` makes the config endpoint return a 4xx, which trips
/// `RemoteConfigManager`'s session kill switch.
final class FixtureServer {

    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    static let offeringsETag = "benchmark-offerings-v1"

    private let factory: BenchmarkPayloadFactory
    private let killSwitchConfig: Bool

    // All responses are precomputed: the fixture path runs on every simulated request of
    // every iteration.
    private let offeringsResponse: Response
    private let offeringsNotModifiedResponse: Response
    private let configResponse: Response
    private let configNotModifiedResponse = Response(statusCode: 204, headers: [:], body: Data())
    private let killSwitchResponse: Response
    private let notFoundResponse: Response

    init(factory: BenchmarkPayloadFactory, killSwitchConfig: Bool = false) {
        self.factory = factory
        self.killSwitchConfig = killSwitchConfig

        let jsonHeadersWithETag = [
            "Content-Type": "application/json",
            HTTPClient.ResponseHeader.eTag.rawValue: Self.offeringsETag
        ]
        self.offeringsResponse = Response(statusCode: 200, headers: jsonHeadersWithETag, body: factory.offeringsData)
        self.offeringsNotModifiedResponse = Response(statusCode: 304, headers: jsonHeadersWithETag, body: Data())
        self.configResponse = Response(
            statusCode: 200,
            headers: ["Content-Type": "application/octet-stream"],
            body: factory.configContainerData
        )
        self.killSwitchResponse = Response(
            statusCode: 400,
            headers: ["Content-Type": "application/json"],
            body: Data(#"{"code": 7000, "message": "benchmark kill switch"}"#.utf8)
        )
        self.notFoundResponse = Response(
            statusCode: 404,
            headers: ["Content-Type": "application/json"],
            body: Data(#"{"code": 7259, "message": "benchmark fixture not found"}"#.utf8)
        )
    }

    func response(for request: URLRequest, bodyData: Data?) -> Response {
        guard let url = request.url else {
            return self.notFoundResponse
        }

        switch RequestKind(url: url) {
        case .offerings:
            let requestETag = request.value(forHTTPHeaderField: HTTPClient.RequestHeader.eTag.rawValue)
            return requestETag == Self.offeringsETag ? self.offeringsNotModifiedResponse : self.offeringsResponse

        case .config:
            if self.killSwitchConfig {
                return self.killSwitchResponse
            }
            if let bodyData,
               let body = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               body["manifest"] as? String == self.factory.configManifest {
                return self.configNotModifiedResponse
            }
            return self.configResponse

        case .blob:
            guard let blobRange = url.path.range(of: "/blobs/"),
                  let blob = self.factory.blobData(forRef: String(url.path[blobRange.upperBound...])) else {
                return self.notFoundResponse
            }
            return Response(statusCode: 200, headers: ["Content-Type": "application/json"], body: blob)
        }
    }

}
