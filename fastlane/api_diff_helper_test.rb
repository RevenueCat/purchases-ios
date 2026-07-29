# Unit tests for ApiDiffHelper's public-api-diff integration.
# Run with: ruby fastlane/api_diff_helper_test.rb

require 'minitest/autorun'
require 'tmpdir'
require_relative 'api_diff_helper'

class ApiDiffHelperTest < Minitest::Test
  NO_CHANGES_OUTPUT = "# ✅ No changes detected\n\n---\n**Analyzed targets:** RevenueCat\n".freeze
  ADDITIONS_OUTPUT = "# 👀 4 public changes detected\n<table><tr><td>❇️</td><td><b>4 Additions</b></td></tr></table>\n".freeze
  MODIFICATIONS_OUTPUT = "# ⚠️ 2 public changes detected ⚠️\n<table><tr><td>🔀</td><td><b>2 Modifications</b></td></tr></table>\n".freeze

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
    [NO_CHANGES_OUTPUT, ADDITIONS_OUTPUT, MODIFICATIONS_OUTPUT].each do |output|
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
end
