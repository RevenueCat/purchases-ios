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

    func startPassthrough(url: URL, startedAt: DispatchTime) {
        let session: URLSession
        switch RequestKind(url: url) {
        case .offerings, .config: session = Self.passthroughAPISession
        case .blob: session = Self.passthroughBlobSession
        }

        let task = session.dataTask(with: self.request) { [weak self] data, response, error in
            guard let self else { return }

            if error != nil {
                Self.record(.failure(url: url, startedAt: startedAt))
                self.client?.urlProtocol(self, didFailWithError: error ?? URLError(.unknown))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.client?.urlProtocol(
                    self,
                    didFailWithError: BenchmarkError.backendFailure("non-HTTP response from \(url.host ?? "")")
                )
                return
            }

            Self.record(.success(
                url: url,
                statusCode: httpResponse.statusCode,
                bytesReceived: data?.count ?? 0,
                startedAt: startedAt
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
