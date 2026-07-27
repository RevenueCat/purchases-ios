# Unit tests for ApiDiffHelper's new-public-API detection.
# Run with: ruby fastlane/api_diff_helper_test.rb

require 'minitest/autorun'
require_relative 'api_diff_helper'

class ApiDiffHelperTest < Minitest::Test
  REPO_URL = "https://github.com/RevenueCat/purchases-ios".freeze

  def test_detects_new_declaration_across_platform_files
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      index 1111111..2222222 100644
      --- a/api/revenuecat-api-ios.swiftinterface
      +++ b/api/revenuecat-api-ios.swiftinterface
      @@ -100,0 +101 @@ extension RevenueCat.Purchases {
      +  public func newThing(with identifier: Swift.String) async throws
      diff --git a/api/revenuecat-api-macos.swiftinterface b/api/revenuecat-api-macos.swiftinterface
      index 3333333..4444444 100644
      --- a/api/revenuecat-api-macos.swiftinterface
      +++ b/api/revenuecat-api-macos.swiftinterface
      @@ -90,0 +91 @@ extension RevenueCat.Purchases {
      +    public func newThing(with identifier: Swift.String) async throws
    DIFF

    changes = ApiDiffHelper.new_api_changes(diff)

    assert ApiDiffHelper.new_api?(changes)
    # Same declaration in two platform files, reported once, indentation stripped.
    assert_equal ["public func newThing(with identifier: Swift.String) async throws"],
                 changes["RevenueCat"][:new]
    assert_empty changes["RevenueCat"][:removed]
  end

  def test_ignores_noise_that_is_not_api
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -1,3 +1,4 @@
      -// swift-compiler-version: Apple Swift version 6.3.1
      +// swift-compiler-version: Apple Swift version 6.3.2
      +import AdServices
      +#if compiler(>=5.3) && $NoncopyableGenerics
      +@available(iOS 15.0, *)
      +@_hasMissingDesignatedInitializers
      +    get
      +  }
    DIFF

    assert_empty ApiDiffHelper.new_api_changes(diff)
  end

  def test_keeps_declarations_that_carry_inline_attributes
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -10,0 +11,2 @@
      +  @objc final public func purchase(product: RevenueCat.StoreProduct)
      +@objc(RCNewThing) public enum NewThing : Swift.Int {
    DIFF

    assert_equal [
      "@objc final public func purchase(product: RevenueCat.StoreProduct)",
      "@objc(RCNewThing) public enum NewThing : Swift.Int {"
    ], ApiDiffHelper.new_api_changes(diff)["RevenueCat"][:new]
  end

  # The point of blacklisting noise instead of whitelisting known keywords: a declaration
  # form we never anticipated still gets reported.
  def test_reports_unanticipated_declaration_forms
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -10,0 +11 @@
      +  public macro SomethingBrandNew() = #externalMacro(module: "X", type: "Y")
    DIFF

    assert_equal ['public macro SomethingBrandNew() = #externalMacro(module: "X", type: "Y")'],
                 ApiDiffHelper.new_api_changes(diff)["RevenueCat"][:new]
  end

  def test_moved_declaration_is_not_reported_as_new
    diff = <<~DIFF
      diff --git a/api/revenuecatui-api-ios.swiftinterface b/api/revenuecatui-api-ios.swiftinterface
      @@ -10 +10 @@
      -  public var body: some SwiftUI.View
      @@ -40,0 +41 @@
      +  public var body: some SwiftUI.View
    DIFF

    assert_empty ApiDiffHelper.new_api_changes(diff)
  end

  def test_reports_removals_alongside_additions
    diff = <<~DIFF
      diff --git a/api/revenuecatui-api-ios.swiftinterface b/api/revenuecatui-api-ios.swiftinterface
      @@ -10 +10 @@
      -  public init(offering: RevenueCat.Offering)
      +  public init(offering: RevenueCat.Offering, displayCloseButton: Swift.Bool)
    DIFF

    changes = ApiDiffHelper.new_api_changes(diff)

    assert_equal ["public init(offering: RevenueCat.Offering, displayCloseButton: Swift.Bool)"],
                 changes["RevenueCatUI"][:new]
    assert_equal ["public init(offering: RevenueCat.Offering)"], changes["RevenueCatUI"][:removed]
  end

  def test_only_removals_is_not_new_api
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -10 +9 @@
      -  public func goneMethod()
    DIFF

    changes = ApiDiffHelper.new_api_changes(diff)

    refute ApiDiffHelper.new_api?(changes)
    assert_equal ["public func goneMethod()"], changes["RevenueCat"][:removed]
  end

  def test_ignores_files_outside_the_api_baselines
    diff = <<~DIFF
      diff --git a/Sources/Purchasing/Purchases.swift b/Sources/Purchasing/Purchases.swift
      @@ -10,0 +11 @@
      +  public func newThing()
    DIFF

    assert_empty ApiDiffHelper.new_api_changes(diff)
  end

  def test_module_attribution_distinguishes_revenuecat_and_revenuecatui
    assert_equal "RevenueCat", ApiDiffHelper.module_for_api_file("api/revenuecat-api-ios.swiftinterface")
    assert_equal "RevenueCatUI", ApiDiffHelper.module_for_api_file("api/revenuecatui-api-ios.swiftinterface")
    assert_nil ApiDiffHelper.module_for_api_file("api/something-else.txt")
  end

  def test_source_link_uses_pr_number_from_squash_commit_subject
    link = ApiDiffHelper.source_link(
      subject: "feat: add new thing (#7290)",
      sha: "ad49327",
      repo_url: REPO_URL
    )

    assert_equal "<#{REPO_URL}/pull/7290|#7290> feat: add new thing", link
  end

  def test_source_link_falls_back_to_commit_without_pr_number
    link = ApiDiffHelper.source_link(subject: "feat: add new thing", sha: "ad49327", repo_url: REPO_URL)

    assert_equal "<#{REPO_URL}/commit/ad49327|ad49327> feat: add new thing", link
  end

  # --- Slack credentials ---

  def test_webhook_credential_posts_to_the_webhook_url
    request = ApiDiffHelper.slack_post_request("hello", webhook_url: "https://hooks.example/abc")

    assert_equal "https://hooks.example/abc", request[:url]
    assert_equal({ text: "hello" }, request[:body])
  end

  # Lets us reuse an existing bot token instead of creating a channel-bound webhook.
  def test_bot_token_credential_posts_to_chat_post_message
    request = ApiDiffHelper.slack_post_request("hello", bot_token: "xoxb-token", channel: "C0123456789")

    assert_equal "https://slack.com/api/chat.postMessage", request[:url]
    assert_equal({ channel: "C0123456789", text: "hello" }, request[:body])
    assert_equal "Bearer xoxb-token", request[:headers]["Authorization"]
  end

  def test_webhook_wins_when_both_credentials_are_present
    request = ApiDiffHelper.slack_post_request("hello", webhook_url: "https://hooks.example/abc",
                                                        bot_token: "xoxb-token", channel: "C1")

    assert_equal "https://hooks.example/abc", request[:url]
  end

  def test_no_credential_means_no_request
    assert_nil ApiDiffHelper.slack_post_request("hello")
    # A bot token without a channel has nowhere to post.
    assert_nil ApiDiffHelper.slack_post_request("hello", bot_token: "xoxb-token")
  end

  # --- Potential API breaks ---

  # Exposing an existing declaration to Objective-C rewrites the line, but removes nothing.
  def test_gaining_an_attribute_is_not_a_break
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -10 +10 @@
      -  final public func overridePreferredUILocale(_ locale: Swift.String?)
      +  @objc final public func overridePreferredUILocale(_ locale: Swift.String?)
    DIFF

    changes = ApiDiffHelper.new_api_changes(diff)

    assert_equal ["@objc final public func overridePreferredUILocale(_ locale: Swift.String?)"],
                 changes["RevenueCat"][:new]
    assert_empty changes["RevenueCat"][:removed]
    assert_empty ApiDiffHelper.break_entries(changes)
  end

  def test_deprecating_a_declaration_is_not_a_break
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -10 +10 @@
      -  final public var hasPaywall: Swift.Bool
      +  @available(*, deprecated, message: "Use somethingElse") final public var hasPaywall: Swift.Bool
    DIFF

    assert_empty ApiDiffHelper.new_api_changes(diff)["RevenueCat"][:removed]
  end

  def test_flags_case_added_to_an_existing_enum
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -3,0 +4 @@
      +  case tenjin = 4
    DIFF
    new_file = <<~SWIFT.lines
      @objc(RCAttributionNetwork) public enum AttributionNetwork : Swift.Int {
        case appleSearchAds = 0
        case adjust = 1
        case tenjin = 4
      }
    SWIFT

    breaks = ApiDiffHelper.breaking_additions(diff) { new_file }

    assert_equal [{ kind: :enum_case, owner: "AttributionNetwork", text: "case tenjin = 4" }],
                 breaks["RevenueCat"]
  end

  # A brand new enum can't break an exhaustive switch that nobody has written yet.
  def test_does_not_flag_cases_of_a_brand_new_enum
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -0,0 +1,3 @@
      +public enum BrandNew : Swift.Int {
      +  case first = 0
      +  case second = 1
    DIFF
    new_file = <<~SWIFT.lines
      public enum BrandNew : Swift.Int {
        case first = 0
        case second = 1
      }
    SWIFT

    assert_empty ApiDiffHelper.breaking_additions(diff) { new_file }
  end

  def test_flags_requirement_added_to_an_existing_protocol
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -2,0 +3 @@
      +  func purchases(_ purchases: RevenueCat.Purchases, didChange: Swift.Bool)
    DIFF
    new_file = <<~SWIFT.lines
      @objc public protocol PurchasesDelegate : ObjectiveC.NSObjectProtocol {
        @objc optional func existing()
        func purchases(_ purchases: RevenueCat.Purchases, didChange: Swift.Bool)
      }
    SWIFT

    breaks = ApiDiffHelper.breaking_additions(diff) { new_file }

    assert_equal :protocol_requirement, breaks["RevenueCat"].first[:kind]
    assert_equal "PurchasesDelegate", breaks["RevenueCat"].first[:owner]
  end

  def test_does_not_flag_optional_protocol_requirement_or_extension_default
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -1,0 +2 @@
      +  @objc optional func newOptional()
      @@ -5,0 +6 @@
      +  public func convenience()
    DIFF
    new_file = <<~SWIFT.lines
      @objc public protocol PurchasesDelegate : ObjectiveC.NSObjectProtocol {
        @objc optional func newOptional()
        func existing()
      }
      extension RevenueCat.PurchasesDelegate {
        public func convenience()
      }
    SWIFT

    assert_empty ApiDiffHelper.breaking_additions(diff) { new_file }
  end

  def test_resolves_the_innermost_enclosing_type_for_nested_enums
    diff = <<~DIFF
      diff --git a/api/revenuecat-api-ios.swiftinterface b/api/revenuecat-api-ios.swiftinterface
      @@ -4,0 +5 @@
      +    case newMode = 2
    DIFF
    new_file = <<~SWIFT.lines
      extension RevenueCat.Purchases {
        public struct Wrapper {
        }
        public enum Mode : Swift.Int {
          case newMode = 2
        }
      }
    SWIFT

    breaks = ApiDiffHelper.breaking_additions(diff) { new_file }

    assert_equal "Mode", breaks["RevenueCat"].first[:owner]
  end

  def test_removal_only_change_reports_as_a_break
    changes = { "RevenueCat" => { new: [], removed: ["public func goneMethod()"] } }

    assert ApiDiffHelper.reportable?(changes)
    message = ApiDiffHelper.api_report_message(changes, status: :landed)

    assert_includes message, ":warning: *Potential API breaks landed on `main`* in RevenueCat"
    assert_includes message, "- removed: public func goneMethod()"
  end

  def test_message_lists_breaks_below_new_api
    changes = { "RevenueCat" => { new: ["public func added()"], removed: ["public func gone()"] } }
    breaks = { "RevenueCat" => [{ kind: :enum_case, owner: "AttributionNetwork", text: "case tenjin = 4" }] }

    message = ApiDiffHelper.api_report_message(changes, breaks_by_module: breaks)

    assert_includes message, ":sparkles: *New public API up for review* in RevenueCat"
    assert_includes message, "+ public func added()"
    assert_includes message, ":warning: *Potential API breaks*"
    assert_includes message, "- removed: public func gone()"
    assert_includes message, "+ new case in AttributionNetwork: case tenjin = 4"
  end

  def test_nothing_to_report_when_there_are_no_changes
    refute ApiDiffHelper.reportable?({}, {})
  end

  def test_message_includes_source_declarations_and_removal_count
    changes = {
      "RevenueCat" => { new: ["public func a()"], removed: [] },
      "RevenueCatUI" => { new: ["public struct B"], removed: ["public struct C"] }
    }

    message = ApiDiffHelper.api_report_message(
      changes,
      source: "<#{REPO_URL}/pull/7290|#7290> feat: add new thing"
    )

    assert_includes message, ":sparkles: *New public API up for review* in RevenueCat, RevenueCatUI"
    assert_includes message, "<#{REPO_URL}/pull/7290|#7290> feat: add new thing"
    assert_includes message, "+ public func a()"
    assert_includes message, "- removed: public struct C"
  end

  def test_landed_message_distinguishes_itself_from_the_review_one
    changes = { "RevenueCat" => { new: ["public func a()"], removed: [] } }

    message = ApiDiffHelper.api_report_message(changes, status: :landed)

    assert_includes message, ":sparkles: *New public API landed on `main`* in RevenueCat"
  end

  def test_pull_request_link
    assert_equal "<#{REPO_URL}/pull/7290|#7290> Add a new thing",
                 ApiDiffHelper.pull_request_link(number: "7290", title: "Add a new thing", repo_url: REPO_URL)
  end

  def test_message_truncates_long_declaration_lists
    new_declarations = (1..15).map { |index| "public func method#{index}()" }
    message = ApiDiffHelper.api_report_message({ "RevenueCat" => { new: new_declarations, removed: [] } })

    assert_includes message, "+ public func method10()"
    refute_includes message, "+ public func method11()"
    assert_includes message, "... and 5 more"
  end
end
