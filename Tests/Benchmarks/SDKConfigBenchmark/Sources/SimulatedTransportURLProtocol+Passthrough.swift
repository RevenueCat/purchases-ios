import Foundation

// MARK: - Passthrough recording (live runs)

extension SimulatedTransportURLProtocol {

    /// Sessions the passthrough re-issues requests on. API traffic mirrors `HTTPClient`'s
    /// pool: ephemeral, no URL cache (the SDK does its own ETag caching), one connection per
    /// host. Blob traffic uses `URLSession.shared`, exactly what the production
    /// `URLSessionRemoteConfigBlobDownloader` defaults to. Injectable for tests.
    static var passthroughAPISession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: configuration)
    }()
    static var passthroughBlobSession: URLSession = .shared

    func startPassthrough(url: URL, iteration: Int, startedAt: DispatchTime) {
        let session: URLSession
        switch RequestKind(url: url) {
        case .offerings, .config: session = Self.passthroughAPISession
        case .blob: session = Self.passthroughBlobSession
        }

        let task = session.dataTask(with: self.request) { [weak self] data, response, error in
            guard let self else { return }

            if error != nil {
                Self.record(.failure(url: url, iteration: iteration, startedAt: startedAt))
                self.client?.urlProtocol(self, didFailWithError: error ?? URLError(.unknown))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                Self.record(.failure(url: url, iteration: iteration, startedAt: startedAt))
                self.client?.urlProtocol(
                    self,
                    didFailWithError: BenchmarkError.backendFailure("non-HTTP response from \(url.host ?? "")")
                )
                return
            }

            Self.record(.success(
                url: url,
                iteration: iteration,
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
