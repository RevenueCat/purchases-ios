import Foundation
@_spi(Internal) import RevenueCat

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewIsolation {

    static let contentRuleListIdentifier = "rc-webview-v2-isolation"

    static var contentBlockingRules: String? {
        """
        [
          {"trigger": {"url-filter": ".*", "resource-type": ["image", "script", "font"], "load-type": ["third-party"]},
           "action": {"type": "block"}},
          {"trigger": {"url-filter": ".*", "resource-type": ["raw"], "load-type": ["third-party"]},
           "action": {"type": "block"}}
        ]
        """
    }

    static var compileRuleList: @MainActor (String, String) async -> WKContentRuleList? = { identifier, rules in
        await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: rules
            ) { ruleList, error in
                if let error {
                    Logger.debug(Strings.paywall_web_view_content_rules_failed(error))
                }
                continuation.resume(returning: ruleList)
            }
        }
    }

    private static var ruleListTask: Task<WKContentRuleList?, Never>?

    @MainActor
    static func ruleList() async -> WKContentRuleList? {
        if let ruleListTask {
            return await ruleListTask.value
        }

        let task = Task<WKContentRuleList?, Never> { @MainActor in
            guard let rules = Self.contentBlockingRules else {
                return nil
            }
            return await Self.compileRuleList(Self.contentRuleListIdentifier, rules)
        }
        self.ruleListTask = task
        return await task.value
    }

    @MainActor
    static func resetRuleListCacheForTests() {
        self.ruleListTask = nil
    }

}

#endif
