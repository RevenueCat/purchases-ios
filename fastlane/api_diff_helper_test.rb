# Unit tests for ApiDiffHelper's public-api-diff integration.
# Run with: ruby fastlane/api_diff_helper_test.rb

require 'minitest/autorun'
require 'tmpdir'
require 'yaml'

# Mock Fastlane::UI for testing
module Fastlane
  module UI
    def self.error(message); end
    def self.success(message); end
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

  def with_interface_files
    Dir.mktmpdir do |dir|
      old_file = File.join(dir, "old.swiftinterface")
      new_file = File.join(dir, "new.swiftinterface")
      File.write(old_file, "public func a()\n")
      File.write(new_file, "public func b()\n")
      yield old_file, new_file, dir
    end
  end

  def test_pinned_version_is_not_the_buggy_orb_default
    assert_equal "0.12.0", ApiDiffHelper::PUBLIC_API_DIFF_VERSION
  end

  # The constant above is not read by anything at CI time; the version that actually ships
  # is the literal in .circleci/default_config.yml. This test parses that YAML (aliases in
  # the file require unsafe_load_file) and checks every revenuecat/install-public-api-diff
  # step against the constant, so editing or deleting the YAML pin fails this test instead
  # of silently drifting back to the orb's buggy 0.10.1 default.
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
