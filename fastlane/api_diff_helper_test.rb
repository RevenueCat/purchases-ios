# Unit tests for ApiDiffHelper's public-api-diff integration.
# Run with: ruby fastlane/api_diff_helper_test.rb

require 'minitest/autorun'
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
      assert_equal ApiDiffHelper::PUBLIC_API_DIFF_VERSION, version
    end
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

  def test_declaration_type_name
    assert_equal "ComponentInteractionType",
                 ApiDiffHelper.declaration_type_name("public enum ComponentInteractionType: Swift.String {")
    assert_equal "Foo", ApiDiffHelper.declaration_type_name("@objc public protocol Foo : NSObjectProtocol {")
    assert_nil ApiDiffHelper.declaration_type_name("public func notAType()")
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

  private

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
