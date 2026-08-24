# Unit tests for ApiDiffHelper's public-api-diff integration.
# Run with: ruby fastlane/api_diff_helper_test.rb

require 'minitest/autorun'
require 'stringio'
require 'tmpdir'
require 'yaml'

# Mock Fastlane::UI for testing
module Fastlane
  module UI
    class << self
      attr_accessor :messages
    end
    self.messages = []

    def self.error(message)
      messages << message
    end

    def self.success(message); end

    def self.message(message); end

    def self.important(message)
      messages << message
    end
  end

  # Mock Fastlane::Actions.sh, used only when the default runner (runner: nil) is exercised.
  # Mirrors fastlane 2.237.0's sh_control_output: when error_callback is given, a non-zero
  # exit does not raise, it calls error_callback with the output and returns that output.
  module Actions
    class << self
      attr_accessor :last_sh_call
    end

    def self.sh(*command, log: true, error_callback: nil)
      self.last_sh_call = { command: command, log: log, error_callback: error_callback }
      output = "boom: bad interface\n"
      error_callback.call(output) if error_callback
      output
    end
  end
end

require_relative 'api_diff_helper'

class ApiDiffHelperTest < Minitest::Test
  NO_CHANGES_OUTPUT = "# ✅ No changes detected\n\n---\n**Analyzed targets:** RevenueCat\n".freeze
  ADDITIONS_OUTPUT = "# 👀 4 public changes detected\n<table><tr><td>❇️</td><td><b>4 Additions</b></td></tr></table>\n".freeze
  MODIFICATIONS_OUTPUT = "# ⚠️ 2 public changes detected ⚠️\n<table><tr><td>🔀</td><td><b>2 Modifications</b></td></tr></table>\n".freeze

  # Captured verbatim from the real 0.12.0 public-api-diff binary run against
  # api/revenuecat-api-ios.swiftinterface with exactly one public declaration added/removed,
  # to prove the singular header (finding: CHANGES_HEADER_PATTERN required "changes", plural
  # only) is a real shape the tool emits, not a hypothetical one.
  SINGLE_ADDITION_OUTPUT = "# \u{1F440} 1 public change detected\n" \
                           "<table><tr><td>❇️</td><td><b>1 Addition</b></td></tr></table>\n" \
                           "\n---\n## `RevenueCat`\n#### ❇️ Added\n```swift\n" \
                           "public func apiDiffHelperFixtureSingleAddition() -> Swift.Int\n```\n" \
                           "\n---\n**Analyzed targets:** RevenueCat\n".freeze
  SINGLE_REMOVAL_OUTPUT = "# ⚠️ 1 public change detected ⚠️\n" \
                          "<table><tr><td>❌</td><td><b>1 Removal</b></td></tr></table>\n" \
                          "\n---\n## `RevenueCat`\n#### ❌ Removed\n```swift\n" \
                          "public func apiDiffHelperFixtureSingleRemoval() -> Swift.Int\n```\n" \
                          "\n---\n**Analyzed targets:** RevenueCat\n".freeze

  def setup
    Fastlane::UI.messages = []
  end

  def with_interface_files
    Dir.mktmpdir do |dir|
      old_file = File.join(dir, "old.swiftinterface")
      new_file = File.join(dir, "new.swiftinterface")
      File.write(old_file, "public func a()\n")
      File.write(new_file, "public func b()\n")
      yield old_file, new_file, dir
    end
  end

  # The version that actually ships is the literal in .circleci/default_config.yml. This test
  # parses that YAML (aliases in the file require unsafe_load_file) and checks every
  # revenuecat/install-public-api-diff step against the constant, so editing or deleting the
  # YAML pin fails this test instead of silently drifting back to the orb's buggy 0.10.1 default.
  def test_ci_config_pins_the_same_version_as_the_constant
    config_path = File.expand_path('../.circleci/default_config.yml', __dir__)
    config = YAML.unsafe_load_file(config_path)

    versions = find_install_public_api_diff_versions(config)

    assert_equal 2, versions.length,
                 "expected exactly two revenuecat/install-public-api-diff steps in .circleci/default_config.yml, " \
                 "found #{versions.length}"
    versions.each do |version|
      assert_equal ApiDiffHelper::PUBLIC_API_DIFF_REF, version
    end
  end

  # Finding 4: pr_labels_for_api_gate calls github_api with no error_handlers, so a non-2xx
  # response raises and reds check-api-changes-* on every PR, including ones with no breaks to
  # judge labels against. fastlane/Fastfile is a DSL evaluated inside Fastlane::FastFile, so it
  # can't be safely required or executed here; this reads the raw source instead and pins two
  # structural invariants: the call site appears after all_breaks has been computed (not before
  # the loop that builds it), and it is conditioned on all_breaks.any? rather than unconditional.
  def test_pr_labels_are_only_fetched_when_there_is_a_break_to_judge
    fastfile_path = File.expand_path('Fastfile', __dir__)
    lines = File.readlines(fastfile_path)

    concat_line_no = lines.index { |line| line.include?("all_breaks.concat(ApiDiffHelper.breaking_changes") }
    refute_nil concat_line_no, "expected to find the loop that accumulates all_breaks"

    # The private_lane definition ("private_lane :pr_labels_for_api_gate do") is a different
    # call shape from the call site; filter it out so we isolate where check_api_changes
    # actually invokes it.
    call_sites = lines.each_with_index.select do |line, _|
      line.include?("pr_labels_for_api_gate") &&
        !line.include?("private_lane :pr_labels_for_api_gate") &&
        !line.strip.start_with?("#")
    end

    assert_equal 1, call_sites.length, "expected exactly one call site for pr_labels_for_api_gate"
    call_line, call_line_no = call_sites.first

    assert call_line_no > concat_line_no,
           "the label fetch must happen after all_breaks is computed, not before"

    # The guard sits above the call rather than on it, so look at the lines leading up to it.
    preceding = lines[(call_line_no - 3)..call_line_no].join
    assert_match(/all_breaks\.any\?/, preceding,
                 "the label fetch must be gated on all_breaks.any?, not unconditional")
  end

  def test_validate_inputs_accepts_two_non_empty_files
    with_interface_files do |old_file, new_file|
      assert_nil ApiDiffHelper.validate_api_diff_inputs!(old_file, new_file)
    end
  end

  def test_validate_inputs_rejects_missing_file
    with_interface_files do |old_file, new_file, dir|
      missing = File.join(dir, "gone.swiftinterface")
      error = assert_raises(RuntimeError) { ApiDiffHelper.validate_api_diff_inputs!(missing, new_file) }
      assert_match(/not found/, error.message)
      assert_match(/gone.swiftinterface/, error.message)
      # Also rejected when it is the new side.
      assert_raises(RuntimeError) { ApiDiffHelper.validate_api_diff_inputs!(old_file, missing) }
    end
  end

  # An empty baseline makes the tool report every declaration as an addition.
  def test_validate_inputs_rejects_empty_file
    with_interface_files do |old_file, new_file, dir|
      empty = File.join(dir, "empty.swiftinterface")
      File.write(empty, "")
      error = assert_raises(RuntimeError) { ApiDiffHelper.validate_api_diff_inputs!(empty, new_file) }
      assert_match(/empty/, error.message)
    end
  end

  def test_validate_output_accepts_recognised_reports
    [
      NO_CHANGES_OUTPUT, ADDITIONS_OUTPUT, MODIFICATIONS_OUTPUT,
      SINGLE_ADDITION_OUTPUT, SINGLE_REMOVAL_OUTPUT
    ].each do |output|
      assert_nil ApiDiffHelper.validate_api_diff_output!(output, "old.swiftinterface", "new.swiftinterface")
    end
  end

  # The tool prints nothing and still exits 0 when an input path is wrong. The previous
  # integration treated empty output as "no changes", which passed CI silently.
  def test_validate_output_rejects_empty_output
    ["", "   \n\n"].each do |output|
      error = assert_raises(RuntimeError) do
        ApiDiffHelper.validate_api_diff_output!(output, "old.swiftinterface", "new.swiftinterface")
      end
      assert_match(/no output/, error.message)
    end
  end

  def test_validate_output_rejects_unrecognised_output
    error = assert_raises(RuntimeError) do
      ApiDiffHelper.validate_api_diff_output!("Segmentation fault: 11\n", "old.swiftinterface", "new.swiftinterface")
    end
    assert_match(/Unrecognized/, error.message)
  end

  def test_api_changes_reported
    refute ApiDiffHelper.api_changes_reported?(NO_CHANGES_OUTPUT)
    assert ApiDiffHelper.api_changes_reported?(ADDITIONS_OUTPUT)
    assert ApiDiffHelper.api_changes_reported?(MODIFICATIONS_OUTPUT)
  end

  # --- Tool invocation ---

  def test_report_passes_expected_arguments_to_the_tool
    with_interface_files do |old_file, new_file|
      received = nil
      runner = ->(*command) { received = command; ADDITIONS_OUTPUT }

      report = ApiDiffHelper.public_api_diff_report(
        tool: "public-api-diff",
        old_file: old_file,
        new_file: new_file,
        target_name: "RevenueCat",
        runner: runner
      )

      assert_equal ADDITIONS_OUTPUT, report
      assert_equal [
        "public-api-diff", "swift-interface",
        "--old", old_file,
        "--new", new_file,
        "--target-name", "RevenueCat"
      ], received
    end
  end

  def test_report_raises_when_the_tool_prints_nothing
    with_interface_files do |old_file, new_file|
      runner = ->(*_command) { "" }

      error = assert_raises(RuntimeError) do
        ApiDiffHelper.public_api_diff_report(
          tool: "public-api-diff", old_file: old_file, new_file: new_file,
          target_name: "RevenueCat", runner: runner
        )
      end
      assert_match(/no output/, error.message)
    end
  end

  def test_report_validates_inputs_before_invoking_the_tool
    with_interface_files do |_old_file, new_file, dir|
      invoked = false
      runner = ->(*_command) { invoked = true; ADDITIONS_OUTPUT }

      assert_raises(RuntimeError) do
        ApiDiffHelper.public_api_diff_report(
          tool: "public-api-diff",
          old_file: File.join(dir, "gone.swiftinterface"),
          new_file: new_file,
          target_name: "RevenueCat",
          runner: runner
        )
      end

      refute invoked, "the tool must not run when an input file is missing"
    end
  end

  # --- Failure output ---

  def test_identical_files_succeed_without_running_the_tool
    Dir.mktmpdir do |dir|
      old_file = File.join(dir, "old.swiftinterface")
      new_file = File.join(dir, "new.swiftinterface")
      File.write(old_file, "public func a()\n")
      File.write(new_file, "public func a()\n")

      invoked = false
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { invoked = true; ADDITIONS_OUTPUT }
      )

      assert result[:success]
      assert_nil result[:diff]
      refute invoked, "no need to explain a difference that does not exist"
    end
  end

  def test_differing_files_report_the_tool_output
    with_interface_files do |old_file, new_file|
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { ADDITIONS_OUTPUT }
      )

      refute result[:success]
      assert_equal "RevenueCat iOS", result[:platform]
      assert_includes result[:diff], "4 public changes detected"
    end
  end

  # Regression coverage for the singular header ("1 public change detected"). The tool
  # pluralizes its own title, and the previous CHANGES_HEADER_PATTERN required "changes",
  # so a single addition or single removal was rejected as unrecognised output and the
  # report was discarded in favor of a generic failure message.
  def test_single_addition_report_is_recognised_and_surfaced
    with_interface_files do |old_file, new_file|
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { SINGLE_ADDITION_OUTPUT }
      )

      refute result[:success]
      assert_includes result[:diff], "1 public change detected"
      refute_includes result[:diff], "public-api-diff failed"
    end
  end

  # Invalid bytes in the tool output must not blow up `.include?`/pattern matching
  # downstream. The old `diff -u` path guarded against this with
  # `.encode('UTF-8', invalid: :replace, undef: :replace)`; that guard was dropped when
  # the tool was swapped in. Without it this raises ArgumentError instead of surfacing
  # the report, and the exercise must go through run_api_diff (not just the validator)
  # because the sanitized string has to be what gets stored in result[:diff].
  def test_invalid_bytes_in_the_report_do_not_crash_validation
    with_interface_files do |old_file, new_file|
      dirty_output = "#{SINGLE_ADDITION_OUTPUT}\xFF\xFE".dup.force_encoding("UTF-8")
      refute dirty_output.valid_encoding?, "the fixture must actually contain invalid bytes"

      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { dirty_output }
      )

      refute result[:success]
      assert_includes result[:diff], "1 public change detected"
      refute_includes result[:diff], "public-api-diff failed"
      assert result[:diff].valid_encoding?
    end
  end

  def test_single_removal_report_is_recognised_and_surfaced
    with_interface_files do |old_file, new_file|
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { SINGLE_REMOVAL_OUTPUT }
      )

      refute result[:success]
      assert_includes result[:diff], "1 public change detected"
      refute_includes result[:diff], "public-api-diff failed"
    end
  end

  # Baselines routinely differ only in the compiler-version comment. Saying so beats
  # printing a report that lists nothing, but the message should only claim what the
  # tool actually proved: it saw no public API changes; it did not diagnose the cause.
  def test_differing_files_with_no_api_change_explain_why
    with_interface_files do |old_file, new_file|
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { NO_CHANGES_OUTPUT }
      )

      refute result[:success]
      assert_includes result[:diff], "reported no public API changes"
      assert_includes result[:diff], "Regenerate the baselines"
    end
  end

  def test_tool_failure_is_surfaced_and_still_fails
    with_interface_files do |old_file, new_file|
      result = ApiDiffHelper.run_api_diff(
        old_file, new_file, "RevenueCat iOS",
        runner: ->(*_command) { "" }
      )

      refute result[:success]
      assert_includes result[:diff], "public-api-diff failed"
      assert_includes result[:diff], "no output"
    end
  end

  # The default runner (used whenever run_api_diff/public_api_diff_report is called without
  # an explicit `runner:`) must pass an error_callback to Fastlane::Actions.sh so the tool's
  # output survives a non-zero exit instead of being replaced by a bare exit-status message.
  # Every other test in this file injects `runner:` and never touches this code path, so
  # without this test the error_callback could be deleted and the suite would stay green.
  def test_default_runner_keeps_log_quiet_but_surfaces_output_via_error_callback
    with_interface_files do |old_file, new_file|
      Fastlane::Actions.last_sh_call = nil

      result = ApiDiffHelper.run_api_diff(old_file, new_file, "RevenueCat iOS")

      call = Fastlane::Actions.last_sh_call
      refute_nil call, "the default runner must invoke Fastlane::Actions.sh"
      assert_equal false, call[:log], "the raw report must stay out of the normal CI log"
      refute_nil call[:error_callback], "an error_callback must be passed so failure output is not lost"
      assert_includes result[:diff], "boom: bad interface"
    end
  end

  def test_missing_baseline_keeps_its_existing_wording
    with_interface_files do |_old_file, new_file, dir|
      result = ApiDiffHelper.run_api_diff(File.join(dir, "gone.swiftinterface"), new_file, "RevenueCat iOS")

      refute result[:success]
      assert_equal "Baseline file missing", result[:diff]
    end
  end

  # --- Merge base baselines ---

  def test_resolve_merge_base_returns_the_sha
    runner = ->(*command) { command == ["git", "merge-base", "origin/main", "HEAD"] ? "abc123def\n" : "" }

    assert_equal "abc123def", ApiDiffHelper.resolve_merge_base(runner: runner)
  end

  # Comparing against nothing would silently report the whole API as new.
  def test_resolve_merge_base_raises_when_empty
    error = assert_raises(RuntimeError) { ApiDiffHelper.resolve_merge_base(runner: ->(*_c) { "\n" }) }

    assert_match(/merge base/, error.message)
  end

  def test_extract_baselines_writes_one_file_per_platform
    Dir.mktmpdir do |dir|
      runner = ->(*command) { "public func fromMergeBase()\n// #{command.last}\n" }

      written = ApiDiffHelper.extract_baselines_at("abc123", dir, "RevenueCat", runner: runner)

      assert_equal ApiDiffHelper::PLATFORM_CHECKS.count, written.count
      assert_includes written, File.join(dir, "revenuecat-api-ios.swiftinterface")
      assert_match(/fromMergeBase/, File.read(File.join(dir, "revenuecat-api-ios.swiftinterface")))
    end
  end

  def test_extract_baselines_asks_git_for_the_right_paths
    Dir.mktmpdir do |dir|
      seen = []
      runner = ->(*command) { seen << command.last; "public func x()\n" }

      ApiDiffHelper.extract_baselines_at("abc123", dir, "RevenueCatUI", runner: runner)

      assert_includes seen, "abc123:api/revenuecatui-api-ios.swiftinterface"
      assert_includes seen, "abc123:api/revenuecatui-api-visionos.swiftinterface"
    end
  end

  def test_extract_baselines_raises_on_an_empty_baseline
    Dir.mktmpdir do |dir|
      error = assert_raises(RuntimeError) do
        ApiDiffHelper.extract_baselines_at("abc123", dir, "RevenueCat", runner: ->(*_c) { "" })
      end

      assert_match(/empty|not found/, error.message)
    end
  end

  # --- Report parsing ---

  # Real 0.12.0 shape: a brand new enum at target level, plus a case added to an existing one.
  ENUM_CASE_REPORT = <<~REPORT.freeze
    # 👀 2 public changes detected
    <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr></table>

    ---
    ## `RevenueCat`
    #### ❇️ Added
    ```swift
    public enum ComponentInteractionType: Swift.String {
      case button
      case carousel
    }
    ```
    ### `PaywallEvent`
    #### ❇️ Added
    ```swift
    case componentInteraction(
      RevenueCat.PaywallEvent.CreationData
    )
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  MODIFIED_REPORT = <<~REPORT.freeze
    # ⚠️ 1 public change detected ⚠️
    <table><tr><td>🔀</td><td><b>1 Modification</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `Configuration.Builder`
    #### 🔀 Modified
    ```swift
    // From
    public func with(preferredUILocaleOverride: Swift.String?) -> RevenueCat.Configuration.Builder

    // To
    @objc
    public func with(preferredUILocaleOverride: Swift.String?) -> RevenueCat.Configuration.Builder

    /**
    Changes:
    - Added attribute `@objc`
    */
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  def test_parse_report_no_changes_yields_nothing
    assert_empty ApiDiffHelper.parse_report(NO_CHANGES_OUTPUT)
  end

  def test_parse_report_separates_target_level_from_member_changes
    changes = ApiDiffHelper.parse_report(ENUM_CASE_REPORT)

    assert_equal 2, changes.count
    whole_type, member = changes

    assert_equal :added, whole_type.kind
    assert_nil whole_type.owner, "a new type sits at target level, not inside a type section"
    assert_match(/public enum ComponentInteractionType/, whole_type.declaration)

    assert_equal :added, member.kind
    assert_equal "PaywallEvent", member.owner
    assert_match(/\Acase componentInteraction\(/, member.declaration)
  end

  def test_parse_report_reads_removals_and_modifications
    removal = ApiDiffHelper.parse_report(SINGLE_REMOVAL_OUTPUT)
    assert_equal [:removed], removal.map(&:kind)
    assert_match(/apiDiffHelperFixtureSingleRemoval/, removal.first.declaration)

    modified = ApiDiffHelper.parse_report(MODIFIED_REPORT)
    assert_equal [:modified], modified.map(&:kind)
    assert_equal "Configuration.Builder", modified.first.owner
  end

  # A report claiming changes that parses to nothing means the format moved under us.
  def test_parse_report_raises_when_it_cannot_find_the_changes_it_announced
    broken = "# 👀 3 public changes detected\nsomething we do not understand\n"

    error = assert_raises(RuntimeError) { ApiDiffHelper.parse_report(broken) }
    assert_match(/could not be parsed/, error.message)
  end

  def test_modification_attribute_only
    assert ApiDiffHelper.modification_attribute_only?(ApiDiffHelper.parse_report(MODIFIED_REPORT).first.declaration)

    signature_change = "// From\npublic func f(a: Swift.Int)\n\n// To\npublic func f(a: Swift.String)\n\n/**\nChanges:\n- Changed parameter type\n*/"
    refute ApiDiffHelper.modification_attribute_only?(signature_change)
  end

  # Finding 2: losing an attribute must never be waved through, whichever attribute it names.
  # Stripping `@objc` from a member on an Obj-C-exposed type breaks every Obj-C caller.
  def test_modification_attribute_only_is_false_when_an_attribute_is_removed
    removed = "// From\n@objc\npublic func f()\n\n// To\npublic func f()\n\n/**\nChanges:\n- Removed attribute `@objc`\n*/"
    refute ApiDiffHelper.modification_attribute_only?(removed)
  end

  # Finding 2: gaining `@available(*, unavailable)` breaks every caller exactly like removing
  # the declaration would, so it must not be exempted as a harmless attribute-only change.
  def test_modification_attribute_only_is_false_when_unavailable_is_added
    unavailable = "// From\npublic func f()\n\n// To\n@available(*, unavailable)\npublic func f()\n\n/**\nChanges:\n- Added attribute `@available(*, unavailable)`\n*/"
    refute ApiDiffHelper.modification_attribute_only?(unavailable)
  end

  # Finding 2: gaining `@available(*, deprecated, ...)` only warns; it is not breaking and must
  # stay exempted, unlike `unavailable`/`obsoleted`.
  def test_modification_attribute_only_is_true_when_deprecated_is_added
    deprecated = "// From\npublic func f()\n\n// To\n@available(*, deprecated, message: \"x\")\npublic func f()\n\n/**\nChanges:\n- Added attribute `@available(*, deprecated, message: \"x\")`\n*/"
    assert ApiDiffHelper.modification_attribute_only?(deprecated)
  end

  def test_declaration_type_name
    assert_equal "ComponentInteractionType",
                 ApiDiffHelper.declaration_type_name("public enum ComponentInteractionType: Swift.String {")
    assert_equal "Foo", ApiDiffHelper.declaration_type_name("@objc public protocol Foo : NSObjectProtocol {")
    assert_nil ApiDiffHelper.declaration_type_name("public func notAType()")
  end

  # --- significant_first_line (shared helper behind Findings 1 and 3) ---

  def test_significant_first_line_skips_a_leading_attribute
    assert_equal "case brandNewError",
                 ApiDiffHelper.significant_first_line("@objc(RCBrandNewError)\ncase brandNewError")
  end

  def test_significant_first_line_skips_the_from_marker
    assert_equal "public func f()", ApiDiffHelper.significant_first_line("// From\npublic func f()")
  end

  def test_significant_first_line_skips_the_from_marker_and_a_stacked_attribute
    assert_equal "public func f()",
                 ApiDiffHelper.significant_first_line("// From\n@objc\npublic func f()")
  end

  # Fail-closed fallback: if every line looks skippable, fall back to the raw first line rather
  # than returning nothing, so an unexpected shape degrades to the un-skipped behavior instead
  # of losing the declaration outright.
  def test_significant_first_line_falls_back_to_the_raw_first_line_when_everything_is_skipped
    assert_equal "// From", ApiDiffHelper.significant_first_line("// From\n@objc\n")
  end

  # Coverage for the three defensive guards: owner/kind reset on target heading,
  # kind reset on type heading, and the elsif check on fence open.

  # Fixture with two target sections: first has a nested member, second has target-level change.
  # Tests that owner = nil is reset when a new ## target heading appears.
  TWO_TARGETS_REPORT = <<~REPORT.freeze
    # 👀 2 public changes detected
    <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `OldType`
    #### ❇️ Added
    ```swift
    case memberOfOldType
    ```

    ---
    ## `RevenueCatUI`
    #### ❇️ Added
    ```swift
    public enum NewTypeInUI: Swift.String {
      case value
    }
    ```

    ---
    **Analyzed targets:** RevenueCat, RevenueCatUI
  REPORT

  def test_parse_report_resets_owner_on_new_target_heading
    changes = ApiDiffHelper.parse_report(TWO_TARGETS_REPORT)

    assert_equal 2, changes.count
    first, second = changes

    # First change is nested under OldType, has an owner
    assert_equal :added, first.kind
    assert_equal "OldType", first.owner
    assert_match(/memberOfOldType/, first.declaration)

    # Second change is target-level (no preceding type section), owner should be nil
    # This would fail if `owner = nil` was removed from the target heading branch
    assert_equal :added, second.kind
    assert_nil second.owner, "target-level changes must have owner=nil"
    assert_match(/NewTypeInUI/, second.declaration)
  end

  # Fixture with a fenced block before any kind heading (orphaned block, should be ignored).
  # Tests that elsif kind prevents a block from being opened/buffered before a kind is set.
  ORPHANED_BLOCK_REPORT = <<~REPORT.freeze
    # 👀 2 public changes detected
    <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `SomeType`
    ```swift
    this fence appears before any kind heading and should be ignored
    ```
    #### ❇️ Added
    ```swift
    public func validChange()
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  def test_parse_report_ignores_fences_before_kind_heading
    changes = ApiDiffHelper.parse_report(ORPHANED_BLOCK_REPORT)

    # Should only parse one change (the one after the kind heading).
    # The orphaned block before the kind should be ignored.
    # This would fail if `elsif kind` became `else` (fence open check would buffer prematurely)
    assert_equal 1, changes.count
    change = changes.first

    assert_equal :added, change.kind
    assert_equal "SomeType", change.owner
    assert_match(/validChange/, change.declaration)
    refute_match(/this fence appears/, change.declaration)
  end

  # Fixture testing kind = nil reset in the ## target branch.
  # A fenced block after a target heading, with no kind heading before it.
  # With the guard: kind is nil so elsif kind refuses to open, no spurious change.
  # Without kind = nil in target branch: stale kind from previous section leaks.
  STALE_KIND_ACROSS_TARGETS_REPORT = <<~REPORT.freeze
    # 👀 2 public changes detected
    <table><tr><td>❌</td><td>1 Removal</b></td><td>❇️</td><td>1 Addition</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `SomeType`
    #### ❌ Removed
    ```swift
    public func removedMember()
    ```

    ---
    ## `RevenueCatUI`
    ```swift
    this fence has no kind heading and should be ignored because kind was reset to nil
    ```

    ---
    **Analyzed targets:** RevenueCat, RevenueCatUI
  REPORT

  def test_parse_report_does_not_leak_kind_across_target_sections
    changes = ApiDiffHelper.parse_report(STALE_KIND_ACROSS_TARGETS_REPORT)

    # Should only parse one change (the removal from RevenueCat).
    # The fence in RevenueCatUI has no kind heading and should be ignored.
    # This would fail if `kind = nil` was removed from the ## target branch,
    # because then the orphaned fence would inherit :removed from the previous section.
    assert_equal 1, changes.count
    change = changes.first

    assert_equal :removed, change.kind
    assert_equal "SomeType", change.owner
    assert_match(/removedMember/, change.declaration)
    refute_match(/this fence has no kind/, change.declaration)

    # Also assert that no change exists with kind :removed and owner nil (the spurious change that would appear without the guard).
    assert_empty changes.select { |c| c.kind == :removed && c.owner.nil? }
  end

  # Fixture where a type section is NOT followed by a kind heading before a fence.
  # This tests that kind = nil is reset on type heading; without it, an orphaned fence
  # in the second type would inherit the previous section's kind.
  TYPE_WITHOUT_KIND_REPORT = <<~REPORT.freeze
    # 👀 2 public changes detected
    <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `TypeWithKind`
    #### ❇️ Added
    ```swift
    case validMember
    ```
    ### `TypeWithoutKind`
    ```swift
    this fence has no kind heading and should be ignored
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  def test_parse_report_does_not_inherit_kind_across_type_sections
    changes = ApiDiffHelper.parse_report(TYPE_WITHOUT_KIND_REPORT)

    # Should only parse one change (the one with an explicit kind heading).
    # The fence in TypeWithoutKind should be ignored because kind is nil.
    # This would fail if `kind = nil` was removed from the type heading branch,
    # because then the orphaned fence would inherit :added from the previous section.
    assert_equal 1, changes.count
    change = changes.first

    assert_equal :added, change.kind
    assert_equal "TypeWithKind", change.owner
    assert_match(/validMember/, change.declaration)
    refute_match(/this fence has no kind/, change.declaration)
  end

  # --- Break rules ---

  def with_interface_containing(text)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "RevenueCat.swiftinterface")
      File.write(path, text)
      yield path
    end
  end

  def test_enclosing_type_kind_classifies_from_the_interface
    with_interface_containing("public enum PaywallEvent : Swift.Codable {\n}\npublic protocol Delegate {\n}\n") do |path|
      assert_equal :enum, ApiDiffHelper.enclosing_type_kind(path, "PaywallEvent")
      assert_equal :protocol, ApiDiffHelper.enclosing_type_kind(path, "Delegate")
      # Dotted owners resolve on their last component.
      assert_equal :enum, ApiDiffHelper.enclosing_type_kind(path, "RevenueCat.PaywallEvent")
      assert_nil ApiDiffHelper.enclosing_type_kind(path, "SomeStruct")
    end
  end

  def test_case_added_to_an_existing_enum_is_a_break
    with_interface_containing("public enum PaywallEvent : Swift.Codable {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(ENUM_CASE_REPORT, path)

      assert_equal 1, breaks.count, "the brand new enum must not be flagged"
      assert_equal :enum_case, breaks.first[:reason]
      assert_equal "PaywallEvent", breaks.first[:owner]
    end
  end

  # The new enum's own cases are inside its declaration block, not separate member changes.
  def test_a_brand_new_enum_is_not_a_break
    report = <<~REPORT
      # 👀 1 public change detected

      ---
      ## `RevenueCat`
      #### ❇️ Added
      ```swift
      public enum BrandNew : Swift.Int {
        case first
      }
      ```
    REPORT

    with_interface_containing("public enum BrandNew : Swift.Int {\n}\n") do |path|
      assert_empty ApiDiffHelper.breaking_changes(report, path)
    end
  end

  def test_removal_is_a_break
    with_interface_containing("public func other()\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(SINGLE_REMOVAL_OUTPUT, path)

      assert_equal [:removed], breaks.map { |b| b[:reason] }
    end
  end

  def test_attribute_only_modification_is_not_a_break
    with_interface_containing("public class Builder {\n}\n") do |path|
      assert_empty ApiDiffHelper.breaking_changes(MODIFIED_REPORT, path)
    end
  end

  def test_signature_change_is_a_break
    report = <<~REPORT
      # ⚠️ 1 public change detected ⚠️

      ---
      ## `RevenueCat`
      ### `Purchases`
      #### 🔀 Modified
      ```swift
      // From
      public func f(a: Swift.Int)

      // To
      public func f(a: Swift.String)

      /**
      Changes:
      - Changed parameter type
      */
      ```
    REPORT

    with_interface_containing("public class Purchases {\n}\n") do |path|
      assert_equal [:modified], ApiDiffHelper.breaking_changes(report, path).map { |b| b[:reason] }
    end
  end

  def test_protocol_requirement_rules
    interface = "public protocol PurchasesDelegate {\n}\n"
    required = <<~REPORT
      # 👀 1 public change detected

      ---
      ## `RevenueCat`
      ### `PurchasesDelegate`
      #### ❇️ Added
      ```swift
      func purchases(_ purchases: RevenueCat.Purchases)
      ```
    REPORT
    optional = required.sub("func purchases", "@objc optional func purchases")

    with_interface_containing(interface) do |path|
      assert_equal [:protocol_requirement], ApiDiffHelper.breaking_changes(required, path).map { |b| b[:reason] }
      assert_empty ApiDiffHelper.breaking_changes(optional, path)
    end
  end

  # Finding 1: a member of a differently-owned type must not be excluded just because it
  # shares a basename with a wholly new type introduced elsewhere in the same report.
  def test_member_of_a_differently_owned_type_sharing_a_new_types_basename_is_still_a_break
    report = <<~REPORT
      # 👀 2 public changes detected

      ---
      ## `RevenueCat`
      #### ❇️ Added
      ```swift
      public enum Config : Swift.Int {
        case first
      }
      ```
      ### `Other.Config`
      #### ❇️ Added
      ```swift
      case second
      ```
    REPORT

    with_interface_containing("public enum Config : Swift.Int {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(report, path)

      assert_equal [:enum_case], breaks.map { |b| b[:reason] }
      assert_equal ["Other.Config"], breaks.map { |b| b[:owner] }
    end
  end

  # Finding 1 (guard-alive): a member reported under a type this same report introduces,
  # under that type's own (undotted) name, must still be excluded. This is the only
  # existing-suite scenario the new_type_names guard actually changes the outcome for, so
  # it's what a mutation check (deleting the guard line) needs to catch.
  # This report shape (a `###` section for a type also reported wholly new) is synthetic,
  # constructed to reach the guard; parse_report's own docstring says the real tool doesn't
  # emit it. It is not captured from an actual public-api-diff run.
  def test_member_reported_separately_for_the_same_new_type_is_not_a_break
    report = <<~REPORT
      # 👀 2 public changes detected

      ---
      ## `RevenueCat`
      #### ❇️ Added
      ```swift
      public enum BrandNewEnum : Swift.Int {
        case first
      }
      ```
      ### `BrandNewEnum`
      #### ❇️ Added
      ```swift
      case second
      ```
    REPORT

    with_interface_containing("public enum BrandNewEnum : Swift.Int {\n}\n") do |path|
      assert_empty ApiDiffHelper.breaking_changes(report, path)
    end
  end

  # Finding 2: classification must ignore prose. A real .swiftinterface preserves
  # @available(..., message: "...") strings verbatim, so a struct whose name happens to
  # appear inside one, or in a preceding // comment, must not be misclassified as an enum.
  def test_enclosing_type_kind_ignores_comments_and_string_literals
    interface = <<~SWIFT
      // Following the enum Foo pattern, this is actually a struct.
      @available(*, deprecated, message: "the enum Foo pattern is deprecated")
      public struct Foo {
      }
    SWIFT

    with_interface_containing(interface) do |path|
      assert_nil ApiDiffHelper.enclosing_type_kind(path, "Foo")
    end
  end

  # Finding 3: `optional` must be recognised only as a modifier immediately preceding the
  # requirement's keyword. A bare substring test would be fooled by a parameter literally
  # named `optional`, silently exempting a real (non-optional) requirement from the gate.
  def test_protocol_requirement_with_parameter_named_optional_is_still_a_break
    interface = "public protocol PurchasesDelegate {\n}\n"
    report = <<~REPORT
      # 👀 1 public change detected

      ---
      ## `RevenueCat`
      ### `PurchasesDelegate`
      #### ❇️ Added
      ```swift
      func purchases(optional flag: Swift.Bool)
      ```
    REPORT

    with_interface_containing(interface) do |path|
      assert_equal [:protocol_requirement], ApiDiffHelper.breaking_changes(report, path).map { |b| b[:reason] }
    end
  end

  # --- Final review wave (2026-07-31): Findings 1-3, captured from the real 0.12.0 binary ---
  #
  # Every fixture below is a verbatim `public-api-diff swift-interface` report, captured by
  # running the real binary against a copy of api/revenuecat-api-ios.swiftinterface with one
  # deliberate edit each. Capture commands (binary at $BIN):
  #
  #   # Finding 1: an @objc(RC...)-attributed case added to the pre-existing @objc ErrorCode enum
  #   $BIN swift-interface --old old.swiftinterface --new new.swiftinterface --target-name RevenueCat
  #   # (new.swiftinterface has one line inserted after ErrorCode's `unknownError` case:
  #   #  `  @objc(RCBrandNewError) case brandNewError = 99`)
  #
  #   # Finding 2: @objc removed from CustomerInfo.expirationDate(forProductIdentifier:)
  #   # (new.swiftinterface drops the leading `@objc ` from that one method line)
  #
  #   # Finding 2: @available(*, unavailable) / @available(*, deprecated, ...) added to
  #   # CustomerInfo.purchaseDate(forEntitlement:) (one attribute line inserted above the method)
  #
  #   # Finding 3 dedup: @objc removed from *two* methods (expirationDate and purchaseDate,
  #   # both forProductIdentifier) within the same CustomerInfo type
  #
  # Findings' root cause: the tool renders an attribute on its own line above the declaration,
  # and a :modified block's fenced text opens with a literal `// From` line, so a naive
  # first-line read only ever sees the attribute or the marker, never the declaration itself.

  ATTRIBUTED_ENUM_CASE_ADDED_REPORT = <<~REPORT.freeze
    # 👀 1 public change detected
    <table><tr><td>❇️</td><td><b>1 Addition</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `ErrorCode`
    #### ❇️ Added
    ```swift
    @objc(RCBrandNewError)
    case brandNewError
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  OBJC_REMOVED_FROM_METHOD_REPORT = <<~REPORT.freeze
    # ⚠️ 1 public change detected ⚠️
    <table><tr><td>🔀</td><td><b>1 Modification</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `CustomerInfo`
    #### 🔀 Modified
    ```swift
    // From
    @objc
    final public func expirationDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    // To
    final public func expirationDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    /**
    Changes:
    - Removed attribute `@objc`
    */
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  UNAVAILABLE_ATTRIBUTE_ADDED_REPORT = <<~REPORT.freeze
    # ⚠️ 1 public change detected ⚠️
    <table><tr><td>🔀</td><td><b>1 Modification</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `CustomerInfo`
    #### 🔀 Modified
    ```swift
    // From
    @objc
    final public func purchaseDate(forEntitlement entitlementIdentifier: Swift.String) -> Foundation.Date?

    // To
    @available(*, unavailable)
    @objc
    final public func purchaseDate(forEntitlement entitlementIdentifier: Swift.String) -> Foundation.Date?

    /**
    Changes:
    - Added attribute `@available(*, unavailable)`
    */
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  DEPRECATED_ATTRIBUTE_ADDED_REPORT = <<~REPORT.freeze
    # ⚠️ 1 public change detected ⚠️
    <table><tr><td>🔀</td><td><b>1 Modification</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `CustomerInfo`
    #### 🔀 Modified
    ```swift
    // From
    @objc
    final public func purchaseDate(forEntitlement entitlementIdentifier: Swift.String) -> Foundation.Date?

    // To
    @available(*, deprecated, message: "use something else")
    @objc
    final public func purchaseDate(forEntitlement entitlementIdentifier: Swift.String) -> Foundation.Date?

    /**
    Changes:
    - Added attribute `@available(*, deprecated, message: "use something else")`
    */
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  # Two distinct removals inside the same type, captured in one run, to prove the dedup fix:
  # before Finding 3's fix both blocks' displayed declaration truncated to the literal
  # "// From" line, so Fastfile's `uniq! { [reason, owner, declaration] }` collapsed them into
  # one, silently dropping a real break.
  TWO_OBJC_REMOVALS_IN_ONE_TYPE_REPORT = <<~REPORT.freeze
    # ⚠️ 2 public changes detected ⚠️
    <table><tr><td>🔀</td><td><b>2 Modifications</b></td></tr></table>

    ---
    ## `RevenueCat`
    ### `CustomerInfo`
    #### 🔀 Modified
    ```swift
    // From
    @objc
    final public func expirationDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    // To
    final public func expirationDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    /**
    Changes:
    - Removed attribute `@objc`
    */
    ```
    ```swift
    // From
    @objc
    final public func purchaseDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    // To
    final public func purchaseDate(forProductIdentifier productIdentifier: RevenueCat.ProductIdentifier) -> Foundation.Date?

    /**
    Changes:
    - Removed attribute `@objc`
    */
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  # A brand new @objc(RC...)-prefixed enum, captured as its own real report shape: the tool
  # puts the attribute on its own line above `public enum ...`, which is exactly what made
  # declaration_type_name (and therefore the new_type_names guard at breaking_changes:364)
  # blind to attributed new types before Finding 3's fix.
  NEW_OBJC_PREFIXED_ENUM_REPORT = <<~REPORT.freeze
    # 👀 1 public change detected
    <table><tr><td>❇️</td><td><b>1 Addition</b></td></tr></table>

    ---
    ## `RevenueCat`
    #### ❇️ Added
    ```swift
    @objc(RCBrandNewEnum)
    public enum BrandNewEnumFixture: Swift.Int {
      case first
      case second
    }
    ```

    ---
    **Analyzed targets:** RevenueCat
  REPORT

  # Finding 1: a case attributed with @objc(RC...) added to a pre-existing @objc enum must
  # still be caught. 20 of 45 public enums in the committed baseline are @objc, and 63 of 152
  # case lines are attributed, so this is the common shape, not an edge case.
  def test_attributed_case_added_to_an_existing_objc_enum_is_a_break
    with_interface_containing("@objc(RCPurchasesErrorCode) public enum ErrorCode : Swift.Int, Swift.Error {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(ATTRIBUTED_ENUM_CASE_ADDED_REPORT, path)

      assert_equal [:enum_case], breaks.map { |b| b[:reason] }
      assert_equal ["ErrorCode"], breaks.map { |b| b[:owner] }
      assert_equal "case brandNewError", breaks.first[:declaration]
    end
  end

  # Finding 2: removing @objc from a method on an Obj-C-exposed class breaks every Obj-C
  # caller, so it must not be exempted as an attribute-only modification.
  def test_removing_objc_from_a_method_is_a_break
    with_interface_containing("public class CustomerInfo : NSObject {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(OBJC_REMOVED_FROM_METHOD_REPORT, path)

      assert_equal [:modified], breaks.map { |b| b[:reason] }
      assert_equal ["CustomerInfo"], breaks.map { |b| b[:owner] }
      assert_match(/final public func expirationDate\(forProductIdentifier/, breaks.first[:declaration])
    end
  end

  # Finding 2: gaining @available(*, unavailable) breaks callers exactly like removing the
  # declaration would.
  def test_adding_unavailable_attribute_is_a_break
    with_interface_containing("public class CustomerInfo : NSObject {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(UNAVAILABLE_ATTRIBUTE_ADDED_REPORT, path)

      assert_equal [:modified], breaks.map { |b| b[:reason] }
    end
  end

  # Finding 2 (fail-open guard-alive): gaining @available(*, deprecated, ...) only warns, so it
  # must stay exempted as attribute-only. Not a break, no false positive.
  def test_adding_deprecated_attribute_is_not_a_break
    with_interface_containing("public class CustomerInfo : NSObject {\n}\n") do |path|
      assert_empty ApiDiffHelper.breaking_changes(DEPRECATED_ATTRIBUTE_ADDED_REPORT, path)
    end
  end

  # Finding 3: two distinct removals in one type must both survive Fastfile's dedup step.
  # breaking_changes itself never dedups (that happens only in Fastfile), so this test mirrors
  # the exact key from fastlane/Fastfile's check_api_changes lane
  # (`uniq! { [change[:reason], change[:owner], change[:declaration]] }`) to prove the two
  # breaks are no longer indistinguishable after Finding 3's fix.
  def test_two_distinct_removals_in_one_type_survive_the_fastfile_dedup_key
    with_interface_containing("public class CustomerInfo : NSObject {\n}\n") do |path|
      breaks = ApiDiffHelper.breaking_changes(TWO_OBJC_REMOVALS_IN_ONE_TYPE_REPORT, path)

      assert_equal 2, breaks.count, "both @objc removals must be reported"
      declarations = breaks.map { |b| b[:declaration] }
      assert_equal declarations.length, declarations.uniq.length,
                   "the two removals must have distinct declaration text, or Fastfile's dedup " \
                   "key collapses them into one"

      deduped = breaks.uniq { |change| [change[:reason], change[:owner], change[:declaration]] }
      assert_equal 2, deduped.count, "distinct removals must survive the Fastfile dedup step"
    end
  end

  # Finding 3: declaration_type_name (and therefore the new_type_names guard it feeds) must
  # resolve an @objc(RC...)-prefixed brand new type, not just an unattributed one.
  def test_declaration_type_name_resolves_an_objc_prefixed_new_type
    change = ApiDiffHelper.parse_report(NEW_OBJC_PREFIXED_ENUM_REPORT).first

    assert_nil change.owner, "a brand new type sits at target level, not inside a type section"
    assert_equal "BrandNewEnumFixture", ApiDiffHelper.declaration_type_name(change.declaration)
  end

  # --- The gate ---

  def test_gate_blocks_on_breaks_without_the_label
    breaks = [{ reason: :removed, owner: nil, declaration: "public func gone()" }]

    assert ApiDiffHelper.gate_blocked?(breaks, [])
    assert ApiDiffHelper.gate_blocked?(breaks, ["pr:other", "pr:RevenueCatUI"])
  end

  def test_label_makes_the_gate_report_only
    breaks = [{ reason: :removed, owner: nil, declaration: "public func gone()" }]

    refute ApiDiffHelper.gate_blocked?(breaks, [ApiDiffHelper::BREAKING_CHANGE_LABEL])
    assert_equal "pr:breaking-api", ApiDiffHelper::BREAKING_CHANGE_LABEL
  end

  def test_gate_passes_when_nothing_is_breaking
    refute ApiDiffHelper.gate_blocked?([], [])
  end

  def test_print_breaking_summary_is_a_noop_when_nothing_is_breaking
    assert_nil ApiDiffHelper.print_breaking_summary([], [])
    assert_empty Fastlane::UI.messages
  end

  def test_print_breaking_summary_without_the_label_tells_you_to_add_it
    breaks = [{ reason: :removed, owner: nil, declaration: "public func gone()" }]

    ApiDiffHelper.print_breaking_summary(breaks, [])

    joined = Fastlane::UI.messages.join("\n")
    assert_includes joined, "removed: public func gone()"
    assert_includes joined, "Add the #{ApiDiffHelper::BREAKING_CHANGE_LABEL} label"
    refute_includes joined, "Reported only"
  end

  def test_print_breaking_summary_with_the_label_reports_only
    breaks = [{ reason: :enum_case, owner: "Foo", declaration: "case bar" }]

    ApiDiffHelper.print_breaking_summary(breaks, [ApiDiffHelper::BREAKING_CHANGE_LABEL])

    joined = Fastlane::UI.messages.join("\n")
    assert_includes joined, "case added to an existing enum in Foo: case bar"
    assert_includes joined, "Reported only"
    refute_includes joined, "Add the #{ApiDiffHelper::BREAKING_CHANGE_LABEL} label"
  end

  # --- Part B: PR comment and Slack ---

  def test_comment_body_carries_the_marker_and_says_no_changes
    body = ApiDiffHelper.api_diff_comment_body({ "RevenueCat iOS" => NO_CHANGES_OUTPUT }, [], [])

    assert body.start_with?(ApiDiffHelper::API_DIFF_COMMENT_MARKER), "the marker is how the upsert finds the comment"
    assert_includes body, "No public API changes."
  end

  def test_comment_body_lists_breaks_and_asks_for_the_label
    breaks = [{ reason: :enum_case, owner: "PaywallEvent", declaration: "case componentInteraction(" }]
    body = ApiDiffHelper.api_diff_comment_body({ "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, breaks, [])

    assert_includes body, "Potential breaking changes"
    assert_includes body, "case added to an existing enum"
    assert_includes body, "`PaywallEvent`"
    assert_includes body, ApiDiffHelper::BREAKING_CHANGE_LABEL
  end

  def test_comment_body_notes_when_the_label_permits_the_break
    breaks = [{ reason: :removed, owner: nil, declaration: "public func gone()" }]
    body = ApiDiffHelper.api_diff_comment_body({}, breaks, [ApiDiffHelper::BREAKING_CHANGE_LABEL])

    assert_includes body, "allowed by label"
    refute_includes body, "Add the `#{ApiDiffHelper::BREAKING_CHANGE_LABEL}` label"
  end

  # The same change is reported once per platform; a comment repeating it nine times is unusable.
  def test_comment_body_collapses_identical_reports_across_platforms
    reports = ApiDiffHelper::PLATFORM_CHECKS.each_with_object({}) do |platform, acc|
      acc["RevenueCat #{platform[:name]}"] = SINGLE_ADDITION_OUTPUT.gsub("RevenueCat", "RevenueCat #{platform[:name]}")
    end

    body = ApiDiffHelper.api_diff_comment_body(reports, [], [])

    assert_equal 1, body.scan("<details>").count, "identical per-platform reports must collapse to one section"
    assert_includes body, "all platforms"
  end

  def test_comment_body_keeps_platform_specific_reports_apart
    reports = {
      "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT,
      "RevenueCat macOS" => SINGLE_REMOVAL_OUTPUT
    }

    body = ApiDiffHelper.api_diff_comment_body(reports, [], [])

    assert_equal 2, body.scan("<details>").count
  end

  def test_slack_summary_leads_with_breaks_when_there_are_any
    breaks = [{ reason: :removed, owner: "CustomerInfo", declaration: "public func gone()" }]

    message = ApiDiffHelper.slack_summary(breaks, [], source: "<url|#42> Some PR", new_declarations: ["public func a()"])

    assert message.start_with?(":warning: *Breaking public API changes*")
    assert_includes message, "<url|#42> Some PR"
    assert_includes message, "1 potential break"
  end

  def test_slack_summary_leads_with_new_api_when_nothing_breaks
    message = ApiDiffHelper.slack_summary([], [], source: "<url|#42> Some PR", new_declarations: ["public func a()", "public var b: Swift.Int"])

    assert message.start_with?(":sparkles: *New public API*")
    assert_includes message, "2 new declarations"
  end


  def test_slack_request_supports_webhook_or_bot_token
    webhook = ApiDiffHelper.slack_post_request("hi", webhook_url: "https://hooks.example/abc")
    assert_equal "https://hooks.example/abc", webhook[:url]
    assert_equal({ text: "hi" }, webhook[:body])

    bot = ApiDiffHelper.slack_post_request("hi", bot_token: "xoxb-t", channel: "C1")
    assert_equal "https://slack.com/api/chat.postMessage", bot[:url]
    assert_equal "Bearer xoxb-t", bot[:headers]["Authorization"]

    assert_nil ApiDiffHelper.slack_post_request("hi"), "no credential means no request"
    assert_nil ApiDiffHelper.slack_post_request("hi", bot_token: "xoxb-t"), "a bot token with no channel has nowhere to post"
  end


  SlackResponse = Struct.new(:code, :body)

  def slack_request
    { url: "https://slack.com/api/chat.postMessage", headers: { "Content-Type" => "application/json" }, body: { channel: "C1", text: "hi" } }
  end

  def test_post_slack_message_posts_the_request_body_as_json
    posted = nil
    poster = ->(url, body, headers) do
      posted = { url: url, body: body, headers: headers }
      SlackResponse.new("200", '{"ok":true}')
    end

    ApiDiffHelper.post_slack_message(slack_request, poster: poster)

    assert_equal "https://slack.com/api/chat.postMessage", posted[:url]
    assert_equal({ "channel" => "C1", "text" => "hi" }, JSON.parse(posted[:body]))
    assert_equal "application/json", posted[:headers]["Content-Type"]
  end

  def test_post_slack_message_raises_on_a_non_success_status
    poster = ->(_url, _body, _headers) { SlackResponse.new("500", "server error") }

    error = assert_raises(RuntimeError) { ApiDiffHelper.post_slack_message(slack_request, poster: poster) }
    assert_match(/500/, error.message)
    assert_match(/server error/, error.message)
  end

  # chat.postMessage answers 200 with ok:false, so the status alone is not the verdict.
  def test_post_slack_message_raises_when_slack_rejects_the_message
    poster = ->(_url, _body, _headers) { SlackResponse.new("200", '{"ok":false,"error":"channel_not_found"}') }

    error = assert_raises(RuntimeError) { ApiDiffHelper.post_slack_message(slack_request, poster: poster) }
    assert_match(/channel_not_found/, error.message)
  end

  # Incoming webhooks answer with the bare string "ok", which is not JSON.
  def test_post_slack_message_accepts_a_non_json_webhook_body
    poster = ->(_url, _body, _headers) { SlackResponse.new("200", "ok") }

    ApiDiffHelper.post_slack_message(slack_request, poster: poster)
  end


  # --- Announcing a change once ---

  def history_getter(texts)
    lambda do |_url, _headers|
      SlackResponse.new("200", { ok: true, messages: texts.map { |text| { "text" => text } } }.to_json)
    end
  end

  def test_slack_history_request_reads_the_channel_with_the_bot_token
    request = ApiDiffHelper.slack_history_request("C1", bot_token: "xoxb-1")

    assert_includes request[:url], "https://slack.com/api/conversations.history?channel=C1"
    assert_equal "Bearer xoxb-1", request[:headers]["Authorization"]
    assert_equal ["new", "old"], ApiDiffHelper.recent_slack_messages(request, getter: history_getter(["new", "old"]))
  end

  def test_recent_slack_messages_raises_when_the_token_cannot_read_the_channel
    getter = ->(_url, _headers) { SlackResponse.new("200", '{"ok":false,"error":"missing_scope"}') }

    error = assert_raises(RuntimeError) do
      ApiDiffHelper.recent_slack_messages(ApiDiffHelper.slack_history_request("C1", bot_token: "xoxb-1"), getter: getter)
    end
    assert_match(/missing_scope/, error.message)
  end

  def announcement(declaration, source: "<url|#7355>", modules: ["RevenueCat"])
    ApiDiffHelper.slack_summary([], [], source: source, new_declarations: [declaration], modules: modules)
  end

  def state_for(message, texts, source: "<url|#7355>", modules: ["RevenueCat"])
    ApiDiffHelper.announcement_state(
      message, bot_token: "xoxb-1", channel: "C1", source: source, modules: modules, getter: history_getter(texts)
    )
  end

  def test_announcement_state_recognises_the_last_word_on_this_pull_request
    summary = announcement("public func a()")

    state, unusable = state_for(summary, [summary, announcement("public func older()")])

    assert_equal :same, state
    assert_nil unusable
  end

  def test_announcement_state_is_different_when_the_pull_request_moved_on_and_back
    summary = announcement("public func a()")

    state, _unusable = state_for(summary, [announcement("public func b()"), summary])

    assert_equal :different, state
  end

  def test_announcement_state_ignores_another_modules_announcement
    summary = announcement("public func a()")
    other_module = announcement("public func a()", modules: ["RevenueCatUI"])

    state, unusable = state_for(summary, [other_module])

    assert_equal :unknown, state
    assert_nil unusable
  end

  def test_announcement_state_ignores_another_pull_requests_announcement
    summary = announcement("public func a()")

    state, _unusable = state_for(summary, [announcement("public func a()", source: "<url|#7354>")])

    assert_equal :unknown, state
  end

  # chat.postMessage takes a `#name`, conversations.history does not.
  def test_announcement_state_needs_the_channel_id
    state, unusable = ApiDiffHelper.announcement_state(
      "summary", bot_token: "xoxb-1", channel: "#feed", source: "<url|#1>", modules: ["RevenueCat"],
      getter: ->(*) { raise "must not read" }
    )

    assert_equal :unknown, state
    assert_match(/channel ID/, unusable)
  end

  def test_announcement_state_reports_a_missing_token
    state, unusable = ApiDiffHelper.announcement_state(
      "summary", bot_token: "", channel: "C1", source: "<url|#1>", modules: ["RevenueCat"]
    )

    assert_equal :unknown, state
    assert_match(/cannot be read/, unusable)
  end

  def test_announcement_state_reports_a_failed_read
    state, unusable = ApiDiffHelper.announcement_state(
      "summary", bot_token: "xoxb-1", channel: "C1", source: "<url|#1>", modules: ["RevenueCat"],
      getter: ->(*) { raise "slack is down" }
    )

    assert_equal :unknown, state
    assert_equal "slack is down", unusable
  end

  def test_announcement_fingerprint_moves_with_the_summary
    first = ApiDiffHelper.slack_summary([], [], source: "<url|#1>", new_declarations: ["public func a()"])
    same = ApiDiffHelper.slack_summary([], [], source: "<url|#1>", new_declarations: ["public func a()"])
    other = ApiDiffHelper.slack_summary([], [], source: "<url|#1>", new_declarations: ["public func b()"])

    assert_equal ApiDiffHelper.announcement_fingerprint(first), ApiDiffHelper.announcement_fingerprint(same)
    refute_equal ApiDiffHelper.announcement_fingerprint(first), ApiDiffHelper.announcement_fingerprint(other)
  end

  def test_no_comment_for_a_pull_request_that_never_touched_the_public_api
    refute ApiDiffHelper.comment_needed?({ "RevenueCat iOS" => NO_CHANGES_OUTPUT }, [], nil, "RevenueCat")
    refute ApiDiffHelper.comment_needed?({}, [], "<!-- api-diff-report -->", "RevenueCat")
  end

  def test_comment_survives_a_pull_request_that_removed_its_api_change
    body = ApiDiffHelper.merge_api_diff_comment(
      nil, "RevenueCat", ApiDiffHelper.api_diff_comment_section("RevenueCat", { "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], [])
    )

    assert ApiDiffHelper.comment_needed?({ "RevenueCat iOS" => NO_CHANGES_OUTPUT }, [], body, "RevenueCat")
    refute ApiDiffHelper.comment_needed?({ "RevenueCatUI iOS" => NO_CHANGES_OUTPUT }, [], body, "RevenueCatUI")
  end

  def test_comment_is_needed_whenever_there_is_anything_to_report
    assert ApiDiffHelper.comment_needed?({ "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], nil, "RevenueCat")
    assert ApiDiffHelper.comment_needed?({}, [{ reason: :removed, owner: nil, declaration: "public func a()" }], nil, "RevenueCat")
  end

  def test_announced_fingerprint_survives_a_run_with_nothing_to_announce
    announced = ApiDiffHelper.merge_api_diff_comment(
      nil, "RevenueCat",
      ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], [], announced_fingerprint: "abc123abc123")
    )

    assert_equal "abc123abc123", ApiDiffHelper.announced_fingerprint_in(announced, "RevenueCat")
    assert_nil ApiDiffHelper.announced_fingerprint_in(announced, "RevenueCatUI")
    assert_nil ApiDiffHelper.announced_fingerprint_in(nil, "RevenueCat")
  end

  # Another module's marker must not be mistaken for this module's.
  def test_announced_fingerprint_is_read_from_this_modules_section
    body = [
      ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], []),
      ApiDiffHelper.api_diff_comment_section("RevenueCatUI", {}, [], [], announced_fingerprint: "def456def456")
    ].join("\n")

    assert_nil ApiDiffHelper.announced_fingerprint_in(body, "RevenueCat")
    assert_equal "def456def456", ApiDiffHelper.announced_fingerprint_in(body, "RevenueCatUI")
  end

  def test_already_announced_reads_the_comment_only_when_the_channel_said_nothing
    body = "## Public API changes\n#{ApiDiffHelper.announced_marker('abc123abc123')}\n"

    assert ApiDiffHelper.already_announced?(:same, "def456def456") { raise "must not read" }
    refute ApiDiffHelper.already_announced?(:different, "abc123abc123") { raise "must not read" }
    assert ApiDiffHelper.already_announced?(:unknown, "abc123abc123") { body }
    refute ApiDiffHelper.already_announced?(:unknown, "def456def456") { body }
    refute ApiDiffHelper.already_announced?(:unknown, "abc123abc123") { nil }
  end

  def test_comment_section_carries_the_announced_fingerprint
    section = ApiDiffHelper.api_diff_comment_section(
      "RevenueCat", { "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], [], announced_fingerprint: "abc123abc123"
    )

    assert_includes section, ApiDiffHelper.announced_marker("abc123abc123")
    assert section.rstrip.end_with?(ApiDiffHelper.api_diff_section_close("RevenueCat"))
  end

  def test_comment_section_omits_the_marker_when_nothing_was_announced
    section = ApiDiffHelper.api_diff_comment_section("RevenueCat", { "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], [])

    refute_includes section, "api-diff-announced"
  end

  def test_merging_a_section_replaces_a_stale_fingerprint
    announced = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], [], announced_fingerprint: "aaaaaaaaaaaa")
    body = ApiDiffHelper.merge_api_diff_comment(nil, "RevenueCat", announced)
    reannounced = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], [], announced_fingerprint: "bbbbbbbbbbbb")

    merged = ApiDiffHelper.merge_api_diff_comment(body, "RevenueCat", reannounced)

    assert_includes merged, ApiDiffHelper.announced_marker("bbbbbbbbbbbb")
    refute_includes merged, ApiDiffHelper.announced_marker("aaaaaaaaaaaa")
  end


  # --- One comment, two jobs ---

  # Two jobs write this comment, one per module. Before sections existed, whichever finished
  # last overwrote the other's findings with its own view.
  def test_merge_starts_a_fresh_comment_with_the_marker
    section = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], [])
    body = ApiDiffHelper.merge_api_diff_comment(nil, "RevenueCat", section)

    assert body.start_with?(ApiDiffHelper::API_DIFF_COMMENT_MARKER)
    assert_includes body, "### RevenueCat"
  end

  def test_merge_preserves_the_other_modules_section
    rc_breaks = [{ reason: :removed, owner: nil, declaration: "public func gone()" }]
    rc = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, rc_breaks, [])
    first = ApiDiffHelper.merge_api_diff_comment(nil, "RevenueCat", rc)

    ui = ApiDiffHelper.api_diff_comment_section("RevenueCatUI", {}, [], [])
    both = ApiDiffHelper.merge_api_diff_comment(first, "RevenueCatUI", ui)

    assert_includes both, "public func gone()", "the RevenueCat findings must survive the RevenueCatUI write"
    assert_includes both, "### RevenueCatUI"
    assert_equal 1, both.scan(ApiDiffHelper::API_DIFF_COMMENT_MARKER).count
  end

  def test_merge_replaces_only_its_own_section_on_a_rerun
    rc_first = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [{ reason: :removed, owner: nil, declaration: "public func gone()" }], [])
    body = ApiDiffHelper.merge_api_diff_comment(nil, "RevenueCat", rc_first)
    body = ApiDiffHelper.merge_api_diff_comment(body, "RevenueCatUI", ApiDiffHelper.api_diff_comment_section("RevenueCatUI", {}, [], []))

    # RevenueCat runs again and now finds nothing.
    rc_second = ApiDiffHelper.api_diff_comment_section("RevenueCat", {}, [], [])
    updated = ApiDiffHelper.merge_api_diff_comment(body, "RevenueCat", rc_second)

    refute_includes updated, "public func gone()", "its own stale finding must be replaced"
    assert_includes updated, "### RevenueCatUI", "the other module's section must remain"
    assert_equal 1, updated.scan("### RevenueCat\n").count
    assert_equal 1, updated.scan(ApiDiffHelper.api_diff_section_open("RevenueCat")).count
  end


  # The message said "9 declarations changed" for a single method, because it counted reports
  # (one per platform) instead of declarations.
  def test_added_declarations_counts_declarations_not_platforms
    reports = ApiDiffHelper::PLATFORM_CHECKS.each_with_object({}) do |platform, acc|
      target = "RevenueCat #{platform[:name]}"
      acc[target] = <<~REPORT
        # 👀 1 public change detected

        ---
        ## `#{target}`
        ### `RevenueCat.Purchases`
        #### ❇️ Added
        ```swift
        @objc
        final public func apiDiffDemoPing() -> Swift.String
        ```
      REPORT
    end

    declarations = ApiDiffHelper.added_declarations(reports)

    assert_equal ["final public func apiDiffDemoPing() -> Swift.String"], declarations,
                 "one declaration on nine platforms is one declaration"
  end

  def test_added_declarations_ignores_unchanged_targets
    assert_empty ApiDiffHelper.added_declarations({ "RevenueCat iOS" => NO_CHANGES_OUTPUT })
  end

  def test_slack_summary_names_the_new_api
    message = ApiDiffHelper.slack_summary([], [], source: "<url|#7355>", new_declarations: ["final public func apiDiffDemoPing() -> Swift.String"])

    assert_includes message, "1 new declaration"
    assert_includes message, "apiDiffDemoPing"
  end

  def test_comment_body_carries_the_slack_notice
    body = ApiDiffHelper.api_diff_comment_body(
      { "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], [], notice: ApiDiffHelper::SLACK_UNREACHABLE_NOTICE
    )

    assert_includes body, ":warning: #{ApiDiffHelper::SLACK_UNREACHABLE_NOTICE}"
  end

  def test_comment_body_omits_the_notice_when_slack_is_reachable
    body = ApiDiffHelper.api_diff_comment_body({ "RevenueCat iOS" => SINGLE_ADDITION_OUTPUT }, [], [])

    refute_includes body, ":warning: No Slack credentials"
  end

  # A PR whose only interface delta is an added attribute reached the feed as a headline and a link,
  # with the headline claiming new API. See purchases-ios#7439.
  def test_slack_summary_reports_an_attribute_only_modification
    modifications = ApiDiffHelper.modified_declarations({ "RevenueCat iOS" => DEPRECATED_ATTRIBUTE_ADDED_REPORT })

    message = ApiDiffHelper.slack_summary([], [], source: "<url|#7439>", modules: ["RevenueCat"], modifications: modifications)

    assert message.start_with?(":pencil2: *Public API changed* · iOS :ios: · `RevenueCat`")
    assert_includes message, "1 modification"
    assert_includes message, "~ added @available(*, deprecated…): "
    assert_includes message, "purchaseDate(forEntitlement"
    refute_includes message, ":sparkles:"
  end

  def test_modified_declarations_summarizes_a_removed_attribute
    modifications = ApiDiffHelper.modified_declarations({ "RevenueCat iOS" => OBJC_REMOVED_FROM_METHOD_REPORT })

    assert_equal 1, modifications.count
    assert_equal "removed @objc", modifications.first[:summary]
    assert_includes modifications.first[:declaration], "expirationDate(forProductIdentifier"
  end

  # Removing @objc is a break, and the gate already lists it; a second `~` line would repeat it.
  def test_slack_summary_lists_a_breaking_modification_once
    modifications = ApiDiffHelper.modified_declarations({ "RevenueCat iOS" => OBJC_REMOVED_FROM_METHOD_REPORT })
    breaks = Dir.mktmpdir do |dir|
      path = File.join(dir, "revenuecat-api-ios.swiftinterface")
      File.write(path, "final public class CustomerInfo {}")
      ApiDiffHelper.breaking_changes(OBJC_REMOVED_FROM_METHOD_REPORT, path)
    end

    message = ApiDiffHelper.slack_summary(breaks, [], source: "", modules: ["RevenueCat"], modifications: modifications)

    assert_equal 1, message.scan("expirationDate(forProductIdentifier").count
    refute_includes message, "modification"
  end

  def test_slack_summary_still_leads_with_new_api_when_something_was_added
    modifications = ApiDiffHelper.modified_declarations({ "RevenueCat iOS" => DEPRECATED_ATTRIBUTE_ADDED_REPORT })

    message = ApiDiffHelper.slack_summary(
      [], [], source: "", new_declarations: ["public func a()"], modules: ["RevenueCat"], modifications: modifications
    )

    assert message.start_with?(":sparkles: *New public API*")
    assert_includes message, "1 new declaration, 1 modification"
    assert_includes message, "+ public func a()"
    assert_includes message, "~ added @available"
  end

  def test_slack_summary_labels_the_platform_and_modules
    message = ApiDiffHelper.slack_summary([], [], source: "<url|#42>", new_declarations: ["public func a()"], modules: ["RevenueCatUI"])

    assert message.start_with?(":sparkles: *New public API* · iOS :ios: · `RevenueCatUI`")
  end

  def test_changed_modules_names_only_the_schemes_that_changed
    reports = {
      "RevenueCat iOS" => NO_CHANGES_OUTPUT,
      "RevenueCatUI iOS" => SINGLE_ADDITION_OUTPUT,
      "RevenueCatUI macOS" => SINGLE_ADDITION_OUTPUT
    }

    assert_equal ["RevenueCatUI"], ApiDiffHelper.changed_modules(reports)
  end

  # A removal-only PR used to show a break count and no declarations at all.
  def test_slack_summary_lists_breaking_declarations
    breaks = [
      { reason: :removed, owner: "CustomerInfo", declaration: "public func gone()" },
      { reason: :modified, owner: nil, declaration: "public func changed() -> Swift.Int" }
    ]

    message = ApiDiffHelper.slack_summary(breaks, [], source: "<url|#42>")

    assert_includes message, "- removed in CustomerInfo: public func gone()"
    assert_includes message, "- signature changed: public func changed() -> Swift.Int"
  end

  # An added enum case is reported by both breaking_changes and added_declarations.
  def test_slack_summary_lists_a_breaking_addition_once
    breaks = [{ reason: :enum_case, owner: "PaywallEvent", declaration: "case newCase" }]

    message = ApiDiffHelper.slack_summary(breaks, [], source: "", new_declarations: ["case newCase", "public func added()"])

    assert_includes message, "- case added to an existing enum in PaywallEvent: case newCase"
    refute_includes message, "+ case newCase"
    assert_includes message, "+ public func added()"
  end

  def test_slack_summary_marks_additions_with_a_plus
    message = ApiDiffHelper.slack_summary([], [], source: "", new_declarations: ["public func added()"])

    assert_includes message, "+ public func added()"
  end

  def test_slack_summary_caps_the_declaration_block
    declarations = (1..15).map { |index| "public func f#{index}()" }

    message = ApiDiffHelper.slack_summary([], [], source: "", new_declarations: declarations)

    assert_includes message, "public func f10()"
    refute_includes message, "public func f11()"
    assert_includes message, "…and 5 more"
  end

  def test_slack_summary_truncates_long_declarations
    long = "public func f(#{'a' * 400})"

    message = ApiDiffHelper.slack_summary([], [], source: "", new_declarations: [long])

    assert_includes message, "…"
    refute_includes message, long
    assert message.lines.all? { |line| line.chomp.length <= ApiDiffHelper::SLACK_DECLARATION_WIDTH }
  end


  # The lane cannot run outside fastlane, so this asserts the structure a review found wrong:
  # the label read used to sit outside the best-effort block, so a GitHub blip aborted the lane
  # before the report was published, exactly when breaks needed reviewing.
  def test_label_read_cannot_abort_before_the_report_is_published
    lane = File.read(File.expand_path("Fastfile", __dir__))
    gate = lane[/labels = \[\].*?gate_blocked\?/m]

    refute_nil gate, "the gate section of check_api_changes moved; update this test"
    assert_match(/begin\s+labels = pr_labels_for_api_gate\s+rescue/, gate,
                 "reading the labels must degrade, not raise")
    assert_operator gate.index("upsert_api_diff_comment"), :>, gate.index("pr_labels_for_api_gate"),
                    "labels are read before publishing, so the read must not be able to abort it"
  end


  # The lane used to hand-roll the post. Keeping it in the helper is what puts the response
  # handling (non-2xx, ok:false, non-JSON webhook body) under test at all.
  def test_the_slack_post_lives_in_the_helper_not_in_the_lane
    lane = File.read(File.expand_path("Fastfile", __dir__))
    slack_lane = lane[/private_lane :notify_api_changes_on_slack do.*?\n  end\n/m]

    refute_nil slack_lane, "the notify_api_changes_on_slack lane moved; update this test"
    refute_match(/Net::HTTP/, slack_lane, "the HTTP post belongs in ApiDiffHelper")
    assert_match(/ApiDiffHelper\.post_slack_message/, slack_lane)
  end

  def test_the_announcement_happens_before_the_comment_is_written
    lane = File.read(File.expand_path("Fastfile", __dir__))
    publishing = lane[/# Informational: a GitHub or Slack outage.*?rescue StandardError/m]

    refute_nil publishing, "the publishing section of check_api_changes moved; update this test"
    assert_operator publishing.index("upsert_api_diff_comment"), :>, publishing.index("notify_api_changes_on_slack"),
                    "the comment must be written after the announcement it records"
  end


  # --- Attribute additions: allowlist, not denylist ---

  def modification_adding(attribute)
    "// From\npublic func f()\n\n// To\npublic func f()\n\n/**\nChanges:\n- Added attribute `#{attribute}`\n*/"
  end

  # These used to slip through: the old check exempted every addition except unavailable and
  # obsoleted, so anything nobody had thought about was waved through.
  def test_constraining_attribute_additions_are_breaking
    ["@MainActor", "@available(iOS 17.0, *)", "@available(*, unavailable)",
     "@available(iOS, obsoleted: 13.0)", "@SomeFutureAttribute"].each do |attribute|
      refute ApiDiffHelper.modification_attribute_only?(modification_adding(attribute)),
             "adding #{attribute} must not be treated as attribute-only"
    end
  end

  def test_harmless_attribute_additions_stay_non_breaking
    ["@objc", "@objc(RCThing)", "@discardableResult", "@inlinable",
     '@available(*, deprecated, message: "use somethingElse")'].each do |attribute|
      assert ApiDiffHelper.modification_attribute_only?(modification_adding(attribute)),
             "adding #{attribute} is additive and must stay non-breaking"
    end
  end

  def test_removing_an_allowlisted_attribute_is_still_breaking
    removal = "// From\npublic func f()\n\n// To\npublic func f()\n\n/**\nChanges:\n- Removed attribute `@objc`\n*/"

    refute ApiDiffHelper.modification_attribute_only?(removal)
  end

  # --- build_swiftinterface: the threaded xcodebuild path ---

  FAKE_XCRUN = <<~'RUBY'
    if ENV["FAKE_XCRUN_EXIT"].to_i != 0
      warn "xcrun: error: SDK \"#{ARGV[ARGV.index('--sdk') + 1]}\" cannot be located"
      exit ENV["FAKE_XCRUN_EXIT"].to_i
    end

    puts "/fake/sdks/#{ARGV[ARGV.index('--sdk') + 1]}.sdk"
  RUBY

  # Writes the interface where the real Release build puts it, so find_swiftinterface_file's
  # per-SDK glob is exercised rather than stubbed.
  FAKE_XCODEBUILD = <<~'RUBY'
    require 'fileutils'
    require 'json'

    def flag(name)
      index = ARGV.index(name)
      index && ARGV[index + 1]
    end

    File.open(ENV.fetch("FAKE_XCODEBUILD_LOG"), "a") do |log|
      log.flock(File::LOCK_EX)
      log.puts(JSON.generate("argv" => ARGV, "cwd" => Dir.pwd))
    end

    if ENV["FAKE_XCODEBUILD_STDOUT"]
      puts ENV["FAKE_XCODEBUILD_STDOUT"]
      warn ENV["FAKE_XCODEBUILD_STDOUT"].sub("stdout", "stderr")
    end

    exit_code = ENV["FAKE_XCODEBUILD_EXIT"].to_i
    exit exit_code unless exit_code.zero?

    unless ENV["FAKE_XCODEBUILD_SKIP_INTERFACE"] == "1"
      sdk = File.basename(flag("-sdk").to_s, ".sdk")
      configuration = sdk == "macosx" ? "Release" : "Release-#{sdk}"
      products = File.join(flag("-derivedDataPath"), "Build", "Products", configuration, "Objects-normal", "arm64")
      FileUtils.mkdir_p(products)
      File.write(File.join(products, "#{flag('-scheme')}.swiftinterface"), "// #{sdk}\n")
    end
  RUBY

  # build_swiftinterface resolves both binaries off PATH, so a directory of fakes in front of it
  # exercises the real code path without a toolchain.
  def with_fake_toolchain(env = {})
    Dir.mktmpdir do |root|
      bin = File.join(root, "bin")
      FileUtils.mkdir_p(bin)
      write_executable(File.join(bin, "xcrun"), FAKE_XCRUN)
      write_executable(File.join(bin, "xcodebuild"), FAKE_XCODEBUILD)

      log = File.join(root, "xcodebuild.jsonl")
      FileUtils.touch(log)

      project_root = File.join(root, "project")
      output_dir = File.join(root, "out")
      FileUtils.mkdir_p([project_root, output_dir])

      overrides = env.merge("PATH" => "#{bin}:#{ENV['PATH']}", "FAKE_XCODEBUILD_LOG" => log)
      with_env(overrides) { yield project_root, output_dir, log }
    end
  end

  def xcodebuild_invocations(log)
    File.readlines(log).map { |line| JSON.parse(line) }
  end

  def build(platform, project_root, output_dir, scheme: "RevenueCat")
    ApiDiffHelper.build_swiftinterface(
      platform,
      scheme: scheme,
      project_root: project_root,
      output_dir: output_dir
    )
  end

  def test_build_swiftinterface_copies_the_generated_interface
    platform = ApiDiffHelper::PLATFORMS.first

    with_fake_toolchain do |project_root, output_dir, log|
      result = build(platform, project_root, output_dir)

      assert result[:success], result[:error]
      assert_equal ["RevenueCat-ios-simulator.swiftinterface"], Dir.children(output_dir)

      invocation = xcodebuild_invocations(log).first
      assert_equal File.realpath(project_root), File.realpath(invocation["cwd"]),
                   "the build must run from the project root without Dir.chdir"
      assert_equal "/fake/sdks/iphonesimulator.sdk", invocation["argv"][invocation["argv"].index("-sdk") + 1]
      assert_equal "#{project_root}/.build-RevenueCat-iphonesimulator",
                   invocation["argv"][invocation["argv"].index("-derivedDataPath") + 1]
    end
  end

  # The whole point of the lane's threading: nine builds at once must not collide, and a shared
  # derived data directory is how they would.
  def test_concurrent_builds_get_their_own_derived_data
    with_fake_toolchain do |project_root, output_dir, log|
      threads = ApiDiffHelper::PLATFORMS.map do |platform|
        Thread.new(platform) { |config| build(config, project_root, output_dir) }
      end
      results = threads.map(&:value)

      assert results.all? { |result| result[:success] }, results.map { |result| result[:error] }.compact.join("\n")
      assert_equal ApiDiffHelper::PLATFORMS.count, Dir.children(output_dir).count

      derived_data = xcodebuild_invocations(log).map do |invocation|
        invocation["argv"][invocation["argv"].index("-derivedDataPath") + 1]
      end
      assert_equal derived_data.count, derived_data.uniq.count, "concurrent builds shared a derived data directory"
    end
  end

  def test_a_scheme_does_not_reuse_another_schemes_derived_data
    platform = ApiDiffHelper::PLATFORMS.first

    with_fake_toolchain do |project_root, output_dir, log|
      ApiDiffHelper::MODULES.each { |scheme| build(platform, project_root, output_dir, scheme: scheme) }

      derived_data = xcodebuild_invocations(log).map do |invocation|
        invocation["argv"][invocation["argv"].index("-derivedDataPath") + 1]
      end
      assert_equal derived_data.count, derived_data.uniq.count
    end
  end

  # Raising inside a thread only surfaces wherever its value is read, so every failure has to come
  # back as a result the lane can collect.
  def test_a_failing_sdk_lookup_is_reported_without_building
    with_fake_toolchain("FAKE_XCRUN_EXIT" => "1") do |project_root, output_dir, log|
      result = build(ApiDiffHelper::PLATFORMS.first, project_root, output_dir)

      refute result[:success]
      assert_match(/xcrun failed for iphonesimulator/, result[:error])
      assert_match(/cannot be located/, result[:error], "the reason the lookup failed must survive")
      assert_empty xcodebuild_invocations(log)
    end
  end

  def test_a_failing_build_is_reported
    with_fake_toolchain("FAKE_XCODEBUILD_EXIT" => "65") do |project_root, output_dir, _log|
      result = build(ApiDiffHelper::PLATFORMS.first, project_root, output_dir)

      refute result[:success]
      assert_match(/xcodebuild failed for RevenueCat on iOS/, result[:error])
      assert_empty Dir.children(output_dir)
    end
  end

  # PLATFORMS reuses one platform label for a device and its simulator, so a failure reported by
  # label alone cannot say which of the two builds died.
  def test_a_failure_names_the_sdk_and_not_only_the_platform
    simulator, device = ApiDiffHelper::PLATFORMS.values_at(0, 1)
    assert_equal simulator[:platform], device[:platform],
                 "this test only means something while the two share a label"

    with_fake_toolchain("FAKE_XCODEBUILD_EXIT" => "65") do |project_root, output_dir, _log|
      errors = [simulator, device].map { |platform| build(platform, project_root, output_dir)[:error] }

      assert_match(/iphonesimulator/, errors.first)
      assert_match(/iphoneos/, errors.last)
      assert_equal 2, errors.uniq.count, "the two failures must be tellable apart"
    end
  end

  # Nine builds write to one stdout at once, so an untagged line cannot be traced to its build.
  def test_build_output_is_tagged_with_the_sdk_that_produced_it
    with_fake_toolchain("FAKE_XCODEBUILD_STDOUT" => "note: stdout marker") do |project_root, output_dir, _log|
      printed = capture_stdout { build(ApiDiffHelper::PLATFORMS[1], project_root, output_dir) }

      assert_includes printed, "[iphoneos] note: stdout marker"
      assert_includes printed, "[iphoneos] note: stderr marker", "stderr has to be tagged too"
    end
  end

  # A build can succeed and still produce nothing when BUILD_LIBRARY_FOR_DISTRIBUTION stops taking.
  def test_a_build_that_emits_no_interface_is_reported
    with_fake_toolchain("FAKE_XCODEBUILD_SKIP_INTERFACE" => "1") do |project_root, output_dir, _log|
      result = build(ApiDiffHelper::PLATFORMS.first, project_root, output_dir)

      refute result[:success]
      assert_match(/Could not find RevenueCat.swiftinterface for iOS/, result[:error])
    end
  end

  # fastlane's `sh` swaps Encoding.default_external for the duration of the call and Dir.chdir
  # moves the whole process, so either one inside the threaded loop would corrupt sibling builds.
  def test_the_generation_lane_keeps_process_global_calls_out_of_the_threads
    lane = File.read(File.expand_path("Fastfile", __dir__))[/lane :generate_swiftinterface do.*?\n  end\n/m]

    refute_nil lane, "the generate_swiftinterface lane moved; update this test"
    assert_match(/Thread\.new/, lane, "the platform builds must still run concurrently")
    refute_match(/Dir\.chdir/, lane, "Dir.chdir moves the whole process, so it cannot run per thread")
    refute_match(/(?<!\w)sh\(/, lane, "fastlane's sh mutates the default encoding, so it cannot run per thread")
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def with_env(overrides)
    original = overrides.keys.to_h { |key| [key, ENV[key]] }
    ENV.update(overrides)
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def write_executable(path, source)
    File.write(path, "#!/usr/bin/env ruby\n#{source}")
    FileUtils.chmod(0o755, path)
  end


  # Walks the parsed CircleCI config looking for CircleCI step hashes of the form
  # `{"revenuecat/install-public-api-diff" => {"version" => "..."}}` and collects the
  # pinned version from each one found, at any depth.
  def find_install_public_api_diff_versions(node, found = [])
    case node
    when Hash
      node.each do |key, value|
        if key == "revenuecat/install-public-api-diff"
          found << (value.is_a?(Hash) ? value["version"] : nil)
        else
          find_install_public_api_diff_versions(value, found)
        end
      end
    when Array
      node.each { |item| find_install_public_api_diff_versions(item, found) }
    end

    found
  end
end
