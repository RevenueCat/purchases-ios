import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) && canImport(WebKit) // For Paywalls V2
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewIsolation {

    static let contentRuleListIdentifier = "rc-webview-v2-isolation"

    static let contentBlockingRules = """
    [
      {
        "trigger": {
          "url-filter": ".*",
          "resource-type": ["image", "script", "font", "raw", "style-sheet", "media", "document"],
          "load-type": ["third-party"]
        },
        "action": {"type": "block"}
      }
    ]
    """

    @MainActor
    static var compileRuleList: @MainActor (String, String) async -> WKContentRuleList? = { identifier, rules in
        await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: rules
            ) { ruleList, error in
                if let error {
                    Logger.debug(Strings.paywall_web_view_content_rules_failed(String(describing: error)))
                }
                continuation.resume(returning: ruleList)
            }
        }
    }

    @MainActor
    private static var ruleListTask: Task<WKContentRuleList?, Never>?

    @MainActor
    static func ruleList() async -> WKContentRuleList? {
        if let ruleListTask {
            return await ruleListTask.value
        }

        let task = Task<WKContentRuleList?, Never> { @MainActor in
            await Self.compileRuleList(Self.contentRuleListIdentifier, Self.contentBlockingRules)
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
