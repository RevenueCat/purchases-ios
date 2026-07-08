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

/// The transport used by every URLSession in the benchmark. Two modes:
///
/// **Simulated**: requests resolve against an in-process `FixtureServer`, so no run can ever
/// touch the real network; fallback-host retries (`api-production.8-lives-cat.io`) resolve
/// against the same fixtures as the primary host. Responses are delivered asynchronously on a
/// private queue: headers after one sampled RTT, then the body in chunks paced by the profile's
/// bandwidth and the loss model's retransmission delays. Nothing here ever blocks a thread, so
/// concurrent requests overlap the way they would on a real connection pool.
///
/// **Passthrough** (live runs): requests are re-issued unmodified against the real network and
/// recorded, so live runs get the same per-request metrics as simulated ones. API hosts go
/// through a single-connection session mirroring `HTTPClient`'s pool; every other host (blob
/// CDNs) goes through a default pool like the production blob downloader's `URLSession.shared`.
final class SimulatedTransportURLProtocol: URLProtocol {

    private enum Mode {
        case simulated(server: FixtureServer, profile: NetworkProfile, loss: LossModel)
        case passthrough
    }

    private static let lock = NSLock()
    private static var mode: Mode?
    private static var seed: UInt64 = 0
    private static var iterationIndex: Int = 0
    /// Requests already planned this iteration, keyed by URL, so retries of the same URL get
    /// distinct (but stable) plans.
    private static var attemptCountsByURL: [String: Int] = [:]
    private static var events: [TransportEvent] = []

    static let chunkSize = 16 * 1024

    /// Serial per request so header, chunks, and completion arrive in order; separate requests
    /// each get their own queue and overlap freely.
    private let deliveryQueue = DispatchQueue(label: "com.revenuecat.benchmark.transport.request")
    private var pendingWorkItems: [DispatchWorkItem] = []
    var passthroughTask: URLSessionDataTask?
    let stateLock = NSLock()

    static func install(server: FixtureServer, profile: NetworkProfile, loss: LossModel, seed: UInt64) {
        self.lock.withLock {
            self.mode = .simulated(server: server, profile: profile, loss: loss)
            self.seed = seed
            self.iterationIndex = 0
            self.attemptCountsByURL = [:]
            self.events = []
        }
    }

    /// Marks the start of an iteration. Request plans are keyed by (seed, iteration, URL,
    /// attempt), so samples stay stable across processes regardless of the order concurrent
    /// requests happen to reach the transport, while still varying between iterations.
    static func beginIteration(_ index: Int) {
        self.lock.withLock {
            self.iterationIndex = index
            self.attemptCountsByURL = [:]
        }
    }

    static func installPassthrough() {
        self.lock.withLock {
            self.mode = .passthrough
            self.events = []
        }
    }

    static func uninstall() {
        self.lock.withLock {
            self.mode = nil
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
        guard self.lock.withLock({ self.mode }) != nil,
              let scheme = request.url?.scheme else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let started = DispatchTime.now()
        guard let url = self.request.url,
              let mode = Self.lock.withLock({ Self.mode }) else {
            self.client?.urlProtocol(
                self,
                didFailWithError: BenchmarkError.invalidFixture("Benchmark transport not installed")
            )
            return
        }

        switch mode {
        case let .simulated(server, profile, loss):
            self.startSimulated(url: url, server: server, profile: profile, loss: loss, startedAt: started)
        case .passthrough:
            self.startPassthrough(url: url, startedAt: started)
        }
    }

    override func stopLoading() {
        self.stateLock.withLock {
            for item in self.pendingWorkItems {
                item.cancel()
            }
            self.pendingWorkItems = []
            self.passthroughTask?.cancel()
            self.passthroughTask = nil
        }
    }

}

// MARK: - Simulated delivery

private extension SimulatedTransportURLProtocol {

    func startSimulated(
        url: URL,
        server: FixtureServer,
        profile: NetworkProfile,
        loss: LossModel,
        startedAt: DispatchTime
    ) {
        let host = url.host ?? ""
        let bodyData = Self.bodyData(of: self.request)
        let response = server.response(for: self.request, bodyData: bodyData)

        // The plan is derived from a stable per-request key, not drawn from a shared RNG in
        // arrival order: concurrent requests reach the transport in a scheduler-dependent
        // order, and order-dependent sampling would make same-seed runs disagree across
        // processes.
        let plan = Self.lock.withLock { () -> RequestPlan in
            let attempt = Self.attemptCountsByURL[url.absoluteString, default: 0]
            Self.attemptCountsByURL[url.absoluteString] = attempt + 1
            return Self.requestPlan(
                key: PlanKey(seed: Self.seed, iteration: Self.iterationIndex, url: url, attempt: attempt),
                bodyCount: response.body.count,
                profile: profile,
                loss: loss
            )
        }

        if plan.fails {
            self.deliverFailure(host: host, path: url.path, rttMs: plan.rttMs, startedAt: startedAt)
        } else {
            self.deliverResponse(
                response,
                url: url,
                profile: profile,
                plan: (plan.rttMs, plan.chunkDelaysMs),
                startedAt: startedAt
            )
        }
    }

}

// MARK: - Delivery helpers

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

}

extension SimulatedTransportURLProtocol {

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
