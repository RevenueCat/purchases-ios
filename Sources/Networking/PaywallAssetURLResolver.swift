//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation

enum PaywallAssetURLResolver {

    static func resolve(_ url: URL, manager: RemoteConfigManagerType) async -> [URL] {
        guard Self.managedOrigin(url) != nil else { return [url] }
        return (try? await manager.readConsistent {
            let sources = await manager.topic(.sources, policy: .cachedOnly)
            return Self.resolve(url, sources: sources)
        }) ?? [url]
    }

    static func resolve(_ url: URL, sources: RemoteConfiguration.ConfigTopic?) -> [URL] {
        guard let origin = Self.managedOrigin(url),
              let original = URLComponents(url: url, resolvingAgainstBaseURL: false),
              case .object(let sourcesByOrigin)? = sources?["assets"]?.content["base_url_sources"],
              case .array(let destinations)? = sourcesByOrigin[origin] else {
            return [url]
        }

        var urls: [URL] = []
        for case .string(let replacement) in destinations.prefix(8) {
            guard let destination = URLComponents(string: replacement),
                  destination.scheme?.lowercased() == "https",
                  destination.host?.isEmpty == false,
                  destination.user == nil,
                  destination.password == nil,
                  destination.port == nil || destination.port == 443,
                  destination.path.isEmpty || destination.path == "/",
                  destination.query == nil,
                  destination.fragment == nil else {
                continue
            }
            var components = original
            components.scheme = "https"
            components.host = destination.host?.lowercased()
            components.port = nil
            if let candidate = components.url, !urls.contains(candidate) {
                urls.append(candidate)
            }
        }
        return urls.isEmpty ? [url] : urls
    }

    static func isCancellation(_ error: Swift.Error) -> Bool {
        return Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    private static func managedOrigin(_ url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              ["assets.pawwalls.com", "fonts.pawwalls.com", "icons.pawwalls.com"].contains(host),
              components.user == nil,
              components.password == nil,
              components.port == nil || components.port == 443 else {
            return nil
        }
        return "https://\(host)"
    }

}
