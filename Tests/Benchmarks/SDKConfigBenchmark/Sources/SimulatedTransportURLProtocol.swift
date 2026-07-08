import Foundation

/// One completed (or failed) simulated request, for phase attribution and byte accounting.
struct TransportEvent {

    let host: String
    let path: String
    let statusCode: Int
    let bytesReceived: Int
    let startedAt: DispatchTime
    let endedAt: DispatchTime
    let failed: Bool

}

/// In-process transport used by every URLSession in the benchmark.
///
/// `canInit` claims EVERY http(s) request, so no benchmark run can ever touch the real network;
/// fallback-host retries (`api-production.8-lives-cat.io`) resolve against the same fixture
/// server as the primary host. Responses are delivered asynchronously on a private queue:
/// headers after one sampled RTT, then the body in chunks paced by the profile's bandwidth and
/// the loss model's retransmission delays. Nothing here ever blocks a thread, so concurrent
/// requests overlap the way they would on a real connection pool.
final class SimulatedTransportURLProtocol: URLProtocol {

    private struct Installation {
        let server: FixtureServer
        let profile: NetworkProfile
        let loss: LossModel
    }

    private static let lock = NSLock()
    private static var installation: Installation?
    private static var rng = SeededRandom(seed: 0)
    private static var events: [TransportEvent] = []

    private static let chunkSize = 16 * 1024

    /// Serial per request so header, chunks, and completion arrive in order; separate requests
    /// each get their own queue and overlap freely.
    private let deliveryQueue = DispatchQueue(label: "com.revenuecat.benchmark.transport.request")
    private var pendingWorkItems: [DispatchWorkItem] = []
    private let stateLock = NSLock()

    static func install(server: FixtureServer, profile: NetworkProfile, loss: LossModel, seed: UInt64) {
        self.lock.withLock {
            self.installation = Installation(server: server, profile: profile, loss: loss)
            self.rng = SeededRandom(seed: seed)
            self.events = []
        }
    }

    static func uninstall() {
        self.lock.withLock {
            self.installation = nil
            self.events = []
        }
    }

    /// Returns all events recorded since the last drain, oldest first.
    static func drainEvents() -> [TransportEvent] {
        return self.lock.withLock {
            let drained = self.events
            self.events = []
            return drained
        }
    }

    /// A URLSession whose requests go through this transport, for injecting into SDK seams
    /// that build their own sessions (e.g. the remote config blob downloader).
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let started = DispatchTime.now()
        guard let url = self.request.url,
              let installation = Self.lock.withLock({ Self.installation }) else {
            self.client?.urlProtocol(
                self,
                didFailWithError: BenchmarkError.invalidFixture("Simulated transport not installed")
            )
            return
        }

        let host = url.host ?? ""
        let bodyData = Self.bodyData(of: self.request)
        let response = installation.server.response(for: self.request, bodyData: bodyData)

        // Sample every random decision up front, under one lock, so the request's timeline is
        // fixed at start time regardless of delivery interleaving.
        let plan: (rttMs: Double, fails: Bool, chunkDelaysMs: [Double]) = Self.lock.withLock {
            let rttMs = installation.profile.rttMs(forHost: host, rng: &Self.rng)
            let fails = installation.loss.shouldFailRequest(rng: &Self.rng)
            var chunkDelaysMs: [Double] = []
            if !fails {
                var offset = 0
                while offset < max(response.body.count, 1) {
                    chunkDelaysMs.append(
                        installation.loss.chunkRetransmitDelayMs(rttMs: rttMs, rng: &Self.rng)
                    )
                    offset += Self.chunkSize
                }
            }
            return (rttMs, fails, chunkDelaysMs)
        }

        if plan.fails {
            self.deliverFailure(host: host, path: url.path, rttMs: plan.rttMs, startedAt: started)
        } else {
            self.deliverResponse(
                response,
                url: url,
                profile: installation.profile,
                plan: (plan.rttMs, plan.chunkDelaysMs),
                startedAt: started
            )
        }
    }

    override func stopLoading() {
        self.stateLock.withLock {
            for item in self.pendingWorkItems {
                item.cancel()
            }
            self.pendingWorkItems = []
        }
    }

}

private extension SimulatedTransportURLProtocol {

    /// One retransmission-timeout's worth of waiting before the failure surfaces, so failed
    /// attempts cost time like they do on a real link.
    func deliverFailure(host: String, path: String, rttMs: Double, startedAt: DispatchTime) {
        let rtoMs = max(1_000, rttMs * 2)
        self.schedule(afterMs: rtoMs) { [weak self] in
            guard let self else { return }
            Self.record(TransportEvent(
                host: host,
                path: path,
                statusCode: 0,
                bytesReceived: 0,
                startedAt: startedAt,
                endedAt: DispatchTime.now(),
                failed: true
            ))
            self.client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
        }
    }

    func deliverResponse(
        _ response: FixtureServer.Response,
        url: URL,
        profile: NetworkProfile,
        plan: (rttMs: Double, chunkDelaysMs: [Double]),
        startedAt: DispatchTime
    ) {
        let host = url.host ?? ""
        guard let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        ) else {
            self.client?.urlProtocol(
                self,
                didFailWithError: BenchmarkError.invalidFixture("Could not create fixture HTTP response")
            )
            return
        }

        var deliveryOffsetMs = plan.rttMs
        self.schedule(afterMs: deliveryOffsetMs) { [weak self] in
            guard let self else { return }
            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        }

        var offset = 0
        var chunkIndex = 0
        while offset < response.body.count {
            let end = min(offset + Self.chunkSize, response.body.count)
            let chunk = response.body.subdata(in: offset..<end)
            deliveryOffsetMs += profile.transferTimeMs(forByteCount: chunk.count)
            deliveryOffsetMs += plan.chunkDelaysMs[min(chunkIndex, plan.chunkDelaysMs.count - 1)]
            self.schedule(afterMs: deliveryOffsetMs) { [weak self] in
                guard let self else { return }
                self.client?.urlProtocol(self, didLoad: chunk)
            }
            offset = end
            chunkIndex += 1
        }

        self.schedule(afterMs: deliveryOffsetMs) { [weak self] in
            guard let self else { return }
            Self.record(TransportEvent(
                host: host,
                path: url.path,
                statusCode: response.statusCode,
                bytesReceived: response.body.count,
                startedAt: startedAt,
                endedAt: DispatchTime.now(),
                failed: false
            ))
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    func schedule(afterMs delayMs: Double, _ work: @escaping () -> Void) {
        let item = DispatchWorkItem(block: work)
        self.stateLock.withLock {
            self.pendingWorkItems.append(item)
        }
        self.deliveryQueue.asyncAfter(deadline: .now() + delayMs / 1_000, execute: item)
    }

    static func record(_ event: TransportEvent) {
        self.lock.withLock {
            self.events.append(event)
        }
    }

    /// URLProtocol surfaces POST bodies as a stream; drain it so the fixture server can
    /// inspect request payloads (the config manifest check needs this).
    static func bodyData(of request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 16 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }

}
