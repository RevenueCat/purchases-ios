import Foundation

/// What a benchmark request is for. Classified once, from the URL, and stamped on every
/// `TransportEvent`, so routing, RTT class, connection pooling, phase attribution, and warm
/// validation all share one rule instead of re-deriving it from path strings.
enum RequestKind {

    case offerings
    case config
    /// Anything that is neither offerings nor config: blob downloads, whose URLs come from the
    /// (real or fixture) config's `url_format` and so have no fixed shape.
    case blob

    init(url: URL) {
        let path = url.path
        if path.hasSuffix("/offerings") {
            self = .offerings
        } else if path.hasSuffix("/config/app") {
            self = .config
        } else {
            self = .blob
        }
    }

}

/// One completed (or failed) simulated request, for phase attribution and byte accounting.
struct TransportEvent {

    let kind: RequestKind
    /// The iteration active when the request STARTED; measurements only aggregate events
    /// stamped with their own iteration, so stragglers from failed or slow earlier launches
    /// can never contaminate a measured row.
    let iteration: Int
    let host: String
    let path: String
    let statusCode: Int
    let bytesReceived: Int
    let startedAt: DispatchTime
    let endedAt: DispatchTime
    let failed: Bool

    /// The SDK's backup hosts; requests here mean the primary host failed over.
    var isFallbackHostRequest: Bool {
        return self.host.contains("8-lives-cat") || self.host.contains("rc-backup")
    }

    static func failure(url: URL, iteration: Int, startedAt: DispatchTime) -> TransportEvent {
        return TransportEvent(
            kind: RequestKind(url: url),
            iteration: iteration,
            host: url.host ?? "",
            path: url.path,
            statusCode: 0,
            bytesReceived: 0,
            startedAt: startedAt,
            endedAt: DispatchTime.now(),
            failed: true
        )
    }

    static func success(
        url: URL,
        iteration: Int,
        statusCode: Int,
        bytesReceived: Int,
        startedAt: DispatchTime
    ) -> TransportEvent {
        return TransportEvent(
            kind: RequestKind(url: url),
            iteration: iteration,
            host: url.host ?? "",
            path: url.path,
            statusCode: statusCode,
            bytesReceived: bytesReceived,
            startedAt: startedAt,
            endedAt: DispatchTime.now(),
            failed: false
        )
    }

}
