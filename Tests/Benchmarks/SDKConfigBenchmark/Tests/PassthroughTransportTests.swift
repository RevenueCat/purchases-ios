import XCTest

@testable import SDKConfigBenchmarkCore

/// Passthrough (live) mode, verified against an in-test stub backend instead of the real
/// network: requests re-issue through the passthrough sessions and get recorded as events.
final class PassthroughTransportTests: BenchmarkTestCase {

    private var originalAPISession: URLSession!
    private var originalBlobSession: URLSession!

    override func setUp() {
        super.setUp()
        self.originalAPISession = SimulatedTransportURLProtocol.passthroughAPISession
        self.originalBlobSession = SimulatedTransportURLProtocol.passthroughBlobSession

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubBackendURLProtocol.self]
        let stubSession = URLSession(configuration: configuration)
        SimulatedTransportURLProtocol.passthroughAPISession = stubSession
        SimulatedTransportURLProtocol.passthroughBlobSession = stubSession
    }

    override func tearDown() {
        SimulatedTransportURLProtocol.uninstall()
        SimulatedTransportURLProtocol.passthroughAPISession = self.originalAPISession
        SimulatedTransportURLProtocol.passthroughBlobSession = self.originalBlobSession
        StubBackendURLProtocol.requestCount = 0
        super.tearDown()
    }

    func testPassthroughForwardsResponseAndRecordsEvent() throws {
        SimulatedTransportURLProtocol.installPassthrough()
        let session = SimulatedTransportURLProtocol.makeSession()
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/subscribers/u/offerings"))

        let expectation = self.expectation(description: "request completes")
        var received: (data: Data?, statusCode: Int?)
        session.dataTask(with: url) { data, response, _ in
            received = (data, (response as? HTTPURLResponse)?.statusCode)
            expectation.fulfill()
        }.resume()
        self.wait(for: [expectation], timeout: 5)

        XCTAssertEqual(received.statusCode, 200)
        XCTAssertEqual(received.data, StubBackendURLProtocol.stubBody)
        XCTAssertEqual(StubBackendURLProtocol.requestCount, 1, "request must reach the (stub) backend")

        let events = SimulatedTransportURLProtocol.drainEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.statusCode, 200)
        XCTAssertEqual(events.first?.bytesReceived, StubBackendURLProtocol.stubBody.count)
        XCTAssertEqual(events.first?.failed, false)
    }

    func testUninstalledTransportDoesNotClaimRequests() {
        SimulatedTransportURLProtocol.uninstall()

        let request = URLRequest(url: URL(fileURLWithPath: "/dev/null"))
        XCTAssertFalse(SimulatedTransportURLProtocol.canInit(with: request))
    }

}

/// Terminal stub for passthrough tests: answers every request on its session with a canned
/// 200 so no test traffic ever leaves the process.
private final class StubBackendURLProtocol: URLProtocol {

    static let stubBody = Data(#"{"stub":true}"#.utf8)
    static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        Self.requestCount += 1
        guard let url = self.request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
              ) else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: Self.stubBody)
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

}
