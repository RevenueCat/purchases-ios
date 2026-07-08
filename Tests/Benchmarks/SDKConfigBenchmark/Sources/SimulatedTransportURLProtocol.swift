import Foundation

/// Placeholder so the `HTTPClient` benchmark hook compiles; replaced with the real
/// simulated transport in a follow-up commit.
final class SimulatedTransportURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {}

    override func stopLoading() {}

}
