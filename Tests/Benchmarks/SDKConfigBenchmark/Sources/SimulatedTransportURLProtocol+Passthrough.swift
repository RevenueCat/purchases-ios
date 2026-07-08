import Foundation

// MARK: - Passthrough recording (live runs)

extension SimulatedTransportURLProtocol {

    /// Sessions the passthrough re-issues requests on. API traffic mirrors `HTTPClient`'s
    /// single-connection-per-host pool; everything else (blob CDNs) gets a default pool like
    /// the production blob downloader's `URLSession.shared`. Injectable for tests.
    static var passthroughAPISession: URLSession = makePassthroughSession(maxConnectionsPerHost: 1)
    static var passthroughBlobSession: URLSession = makePassthroughSession(maxConnectionsPerHost: nil)

    private static func makePassthroughSession(maxConnectionsPerHost: Int?) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        if let maxConnectionsPerHost {
            configuration.httpMaximumConnectionsPerHost = maxConnectionsPerHost
        }
        return URLSession(configuration: configuration)
    }

    static func isAPIHost(_ host: String) -> Bool {
        return host.contains("revenuecat.com") && host.hasPrefix("api.")
            || host.contains("8-lives-cat")
            || host.contains("rc-backup")
    }

    func startPassthrough(url: URL, startedAt: DispatchTime) {
        let host = url.host ?? ""
        let session = Self.isAPIHost(host) ? Self.passthroughAPISession : Self.passthroughBlobSession

        let task = session.dataTask(with: self.request) { [weak self] data, response, error in
            guard let self else { return }
            let ended = DispatchTime.now()

            if let error {
                Self.record(TransportEvent(
                    host: host,
                    path: url.path,
                    statusCode: 0,
                    bytesReceived: 0,
                    startedAt: startedAt,
                    endedAt: ended,
                    failed: true
                ))
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.client?.urlProtocol(
                    self,
                    didFailWithError: BenchmarkError.backendFailure("non-HTTP response from \(host)")
                )
                return
            }

            Self.record(TransportEvent(
                host: host,
                path: url.path,
                statusCode: httpResponse.statusCode,
                bytesReceived: data?.count ?? 0,
                startedAt: startedAt,
                endedAt: ended,
                failed: false
            ))
            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            if let data, !data.isEmpty {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        self.stateLock.withLock {
            self.passthroughTask = task
        }
        task.resume()
    }

}
