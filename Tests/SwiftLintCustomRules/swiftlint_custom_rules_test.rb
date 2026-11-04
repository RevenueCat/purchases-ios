# Tests for the custom SwiftLint rules in .swiftlint.yml.
# Each Fixtures/<rule_id>.swift.fixture is linted as Sources/<rule_id>.swift. Every line ending in
# `// violation` must be reported by that rule, and no other line may be.
# Run with: ruby Tests/SwiftLintCustomRules/swiftlint_custom_rules_test.rb

require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'

class SwiftLintCustomRulesTest < Minitest::Test
  REPO_ROOT = File.expand_path('../..', __dir__)
  FIXTURES_DIR = File.join(__dir__, 'Fixtures')
  SWIFTLINT = ENV.fetch('SWIFTLINT', 'swiftlint')
  VIOLATION_MARKER = '// violation'
  SWIFTLINT_EXIT_CODES = [0, 2].freeze # 2 means violations were found

  Dir.glob(File.join(FIXTURES_DIR, '*.swift.fixture')).sort.each do |fixture|
    rule_id = File.basename(fixture, '.swift.fixture')

    define_method("test_#{rule_id}") do
      expected = expected_lines(fixture)
      refute_empty expected, "#{fixture} has no `#{VIOLATION_MARKER}` lines"
      actual = reported_lines(fixture, rule_id)
      assert_equal expected, actual,
                   "#{rule_id}: missed lines #{expected - actual}, unexpected lines #{actual - expected}"
    end
  end

  private

  def expected_lines(fixture)
    File.readlines(fixture)
        .each_with_index
        .select { |line, _| line.include?(VIOLATION_MARKER) }
        .map { |_, index| index + 1 }
  end

  def reported_lines(fixture, rule_id)
    Dir.mktmpdir do |dir|
      file = File.join('Sources', "#{rule_id}.swift")
      FileUtils.mkdir_p(File.join(dir, 'Sources'))
      FileUtils.cp(fixture, File.join(dir, file))
      File.write(File.join(dir, 'swiftlint-baseline.json'), '[]')

      stdout, stderr, status = Open3.capture3(
        SWIFTLINT, 'lint', '--no-cache', '--quiet',
        '--config', File.join(REPO_ROOT, '.swiftlint.yml'),
        '--reporter', 'json',
        file,
        chdir: dir
      )
      assert_includes SWIFTLINT_EXIT_CODES, status.exitstatus, "swiftlint failed: #{stderr}"

      JSON.parse(stdout)
          .select { |violation| violation['rule_id'] == rule_id }
          .map { |violation| violation['line'] }
          .sort
    end
  end
end
