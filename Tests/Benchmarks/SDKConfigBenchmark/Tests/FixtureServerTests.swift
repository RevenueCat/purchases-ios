import XCTest

@testable import SDKConfigBenchmarkCore

final class FixtureServerTests: BenchmarkTestCase {

    private let factory = BenchmarkPayloadFactory(paywallCount: 3, workflowCount: 4)
    private var server: FixtureServer!

    override func setUp() {
        super.setUp()
        self.server = FixtureServer(factory: self.factory)
    }

    override func tearDown() {
        SimulatedTransportURLProtocol.uninstall()
        super.tearDown()
    }

    private func request(_ urlString: String, eTag: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: try XCTUnwrap(URL(string: urlString)))
        if let eTag {
            request.setValue(eTag, forHTTPHeaderField: "X-RevenueCat-ETag")
        }
        return request
    }

    func testOfferingsServes200WithETagThen304OnMatch() throws {
        let url = "https://api.revenuecat.com/v1/subscribers/user-1/offerings"

        let cold = self.server.response(for: try self.request(url), bodyData: nil)
        XCTAssertEqual(cold.statusCode, 200)
        XCTAssertEqual(cold.headers["X-RevenueCat-ETag"], FixtureServer.offeringsETag)
        XCTAssertEqual(cold.body, self.factory.offeringsData)

        let warm = self.server.response(
            for: try self.request(url, eTag: FixtureServer.offeringsETag),
            bodyData: nil
        )
        XCTAssertEqual(warm.statusCode, 304)
        XCTAssertEqual(warm.headers["X-RevenueCat-ETag"], FixtureServer.offeringsETag)
        XCTAssertTrue(warm.body.isEmpty)
    }

    func testOfferingsFallbackHostPathRoutesIdentically() throws {
        let fallback = self.server.response(
            for: try self.request("https://api-production.8-lives-cat.io/v1/offerings"),
            bodyData: nil
        )

        XCTAssertEqual(fallback.statusCode, 200)
        XCTAssertEqual(fallback.body, self.factory.offeringsData)
    }

    func testConfigServes200ContainerThen204OnMatchingManifest() throws {
        let url = "https://api.revenuecat.com/v1/config/app"

        let cold = self.server.response(for: try self.request(url), bodyData: Data(#"{"appUserId":"u"}"#.utf8))
        XCTAssertEqual(cold.statusCode, 200)
        XCTAssertEqual(cold.body, self.factory.configContainerData)

        let warmBody = Data(#"{"appUserId":"u","manifest":"benchmark-manifest-v1"}"#.utf8)
        let warm = self.server.response(for: try self.request(url), bodyData: warmBody)
        XCTAssertEqual(warm.statusCode, 204)
        XCTAssertTrue(warm.body.isEmpty)
    }

    func testKillSwitchConfigReturns400ButOfferingsStillServe() throws {
        let killServer = FixtureServer(factory: self.factory, killSwitchConfig: true)

        let config = killServer.response(
            for: try self.request("https://api.revenuecat.com/v1/config/app"),
            bodyData: nil
        )
        XCTAssertEqual(config.statusCode, 400)

        let offerings = killServer.response(
            for: try self.request("https://api.revenuecat.com/v1/subscribers/u/offerings"),
            bodyData: nil
        )
        XCTAssertEqual(offerings.statusCode, 200)
    }

    func testBlobRefRoundTrip() throws {
        let ref = try XCTUnwrap(self.factory.allBlobRefs.first)

        let response = self.server.response(
            for: try self.request("https://cdn.revenuecat.local/blobs/\(ref)"),
            bodyData: nil
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.body, self.factory.blobData(forRef: ref))
    }

    func testUnknownPathReturns404() throws {
        let response = self.server.response(
            for: try self.request("https://api.revenuecat.com/v1/unknown"),
            bodyData: nil
        )

        XCTAssertEqual(response.statusCode, 404)
    }

    // MARK: - Transport integration

    private func installTransport(lossPercent: Int = 0) {
        SimulatedTransportURLProtocol.install(
            server: self.server,
            profile: .ideal,
            loss: LossModel(lossPercent: lossPercent),
            seed: 42
        )
    }

    private func fetch(_ urlString: String, timeout: TimeInterval = 10) throws -> (data: Data?,
                                                                                   statusCode: Int?,
                                                                                   error: Error?) {
        let url = try XCTUnwrap(URL(string: urlString))
        let session = SimulatedTransportURLProtocol.makeSession()

        let expectation = self.expectation(description: "request completes")
        let result = LockedValue<(Data?, Int?, Error?)>()
        session.dataTask(with: url) { data, response, error in
            result.set((data, (response as? HTTPURLResponse)?.statusCode, error))
            expectation.fulfill()
        }.resume()
        self.wait(for: [expectation], timeout: timeout)

        let (data, statusCode, error) = result.get() ?? (nil, nil, nil)
        return (data, statusCode, error)
    }

    func testTransportDeliversFixtureBodyAndRecordsEvent() throws {
        self.installTransport()
        let ref = try XCTUnwrap(self.factory.allBlobRefs.first)

        let received = try self.fetch("https://cdn.revenuecat.local/blobs/\(ref)")

        XCTAssertNil(received.error)
        XCTAssertEqual(received.statusCode, 200)
        XCTAssertEqual(received.data, self.factory.blobData(forRef: ref))

        let events = SimulatedTransportURLProtocol.drainEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.host, "cdn.revenuecat.local")
        XCTAssertEqual(events.first?.kind, .blob)
        XCTAssertEqual(events.first?.bytesReceived, self.factory.blobData(forRef: ref)?.count)
        XCTAssertTrue(SimulatedTransportURLProtocol.drainEvents().isEmpty, "drain must clear events")
    }

    func testTransportInterceptsRealAPIHostsSoNothingLeaks() throws {
        self.installTransport()

        let received = try self.fetch("https://api.revenuecat.com/v1/subscribers/u/offerings")

        XCTAssertEqual(received.data, self.factory.offeringsData, "real API hosts must resolve to fixtures")
    }

    func testTransportModelsLossAsTimedOutFailure() throws {
        self.installTransport(lossPercent: 100)

        let received = try self.fetch("https://api.revenuecat.com/v1/subscribers/u/offerings")

        XCTAssertEqual((received.error as? URLError)?.code, .timedOut)

        let events = SimulatedTransportURLProtocol.drainEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events.first?.failed == true)
    }

}
