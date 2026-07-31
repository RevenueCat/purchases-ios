# Helper module for API diff functionality
# Used by generate_swiftinterface and check_api_changes lanes

require 'fileutils'

module ApiDiffHelper
  MODULES = ["RevenueCat", "RevenueCatUI"].freeze

  PLATFORMS = [
    {
      sdk: "iphonesimulator",
      platform: "iOS",
      suffix: "-ios-simulator",
      destination: "generic/platform=iOS Simulator"
    },
    {
      sdk: "iphoneos",
      platform: "iOS",
      suffix: "-ios",
      destination: "generic/platform=iOS"
    },
    {
      sdk: "macosx",
      platform: "macOS",
      suffix: "-macos",
      destination: "generic/platform=macOS"
    },
    {
      sdk: "watchsimulator",
      platform: "watchOS",
      suffix: "-watchos-simulator",
      destination: "generic/platform=watchOS Simulator"
    },
    {
      sdk: "watchos",
      platform: "watchOS",
      suffix: "-watchos",
      destination: "generic/platform=watchOS"
    },
    {
      sdk: "appletvsimulator",
      platform: "tvOS",
      suffix: "-tvos-simulator",
      destination: "generic/platform=tvOS Simulator"
    },
    {
      sdk: "appletvos",
      platform: "tvOS",
      suffix: "-tvos",
      destination: "generic/platform=tvOS"
    },
    {
      sdk: "xrsimulator",
      platform: "visionOS",
      suffix: "-visionos-simulator",
      destination: "generic/platform=visionOS Simulator"
    },
    {
      sdk: "xros",
      platform: "visionOS",
      suffix: "-visionos",
      destination: "generic/platform=visionOS"
    },
  ].freeze

  PLATFORM_CHECKS = [
    { suffix: "-ios-simulator", name: "iOS Simulator" },
    { suffix: "-ios", name: "iOS" },
    { suffix: "-macos", name: "macOS" },
    { suffix: "-watchos-simulator", name: "watchOS Simulator" },
    { suffix: "-watchos", name: "watchOS" },
    { suffix: "-tvos-simulator", name: "tvOS Simulator" },
    { suffix: "-tvos", name: "tvOS" },
    { suffix: "-visionos-simulator", name: "visionOS Simulator" },
    { suffix: "-visionos", name: "visionOS" }
  ].freeze

  PR_SWIFTINTERFACE_DIR = "/tmp/pr-swiftinterface".freeze

  module_function

  def api_file_prefix(scheme)
    scheme.downcase
  end

  def swiftinterface_pattern_for_sdk(sdk, module_name)
    case sdk
    when "iphonesimulator"
      "**/Release-iphonesimulator/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "iphoneos"
      "**/Release-iphoneos/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "macosx"
      "**/Release/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "watchsimulator"
      "**/Release-watchsimulator/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "watchos"
      "**/Release-watchos/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "appletvsimulator"
      "**/Release-appletvsimulator/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "appletvos"
      "**/Release-appletvos/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "xrsimulator"
      "**/Release-xrsimulator/**/Objects-normal/**/#{module_name}.swiftinterface"
    when "xros"
      "**/Release-xros/**/Objects-normal/**/#{module_name}.swiftinterface"
    else
      "**/#{module_name}.swiftinterface"
    end
  end

  def find_swiftinterface_file(derived_data_dir, sdk, module_name)
    pattern = swiftinterface_pattern_for_sdk(sdk, module_name)
    Dir.glob("#{derived_data_dir}/#{pattern}")
       .reject { |path| path.include?("private") }
  end

  def copy_generated_swiftinterface_files(destination_dir, schemes = MODULES)
    Array(schemes).each do |scheme|
      prefix = api_file_prefix(scheme)

      PLATFORM_CHECKS.each do |platform|
        src = "#{PR_SWIFTINTERFACE_DIR}/#{scheme}#{platform[:suffix]}.swiftinterface"
        dst = File.join(destination_dir, "#{prefix}-api#{platform[:suffix]}.swiftinterface")

        if File.exist?(src)
          FileUtils.cp(src, dst)
          Fastlane::UI.success("Updated #{dst}")
        else
          Fastlane::UI.error("Missing generated file: #{src}")
        end
      end
    end
  end

  def run_api_diff(old_file, new_file, platform_name, tool: "public-api-diff", runner: nil)
    result = {
      platform: platform_name,
      success: false,
      diff: nil
    }

    unless File.exist?(old_file)
      Fastlane::UI.error("Baseline interface file not found: #{old_file}")
      result[:diff] = "Baseline file missing"
      return result
    end

    unless File.exist?(new_file)
      Fastlane::UI.error("New interface file not found: #{new_file}")
      result[:diff] = "New file missing"
      return result
    end

    if FileUtils.identical?(old_file, new_file)
      Fastlane::UI.success("✅ No API changes for #{platform_name}")
      result[:success] = true
      return result
    end

    Fastlane::UI.error("❌ API changes detected for #{platform_name}")

    begin
      report = public_api_diff_report(
        tool: tool,
        old_file: old_file,
        new_file: new_file,
        target_name: platform_name,
        runner: runner
      )

      result[:diff] = if api_changes_reported?(report)
                        report
                      else
                        "public-api-diff reported no public API changes, but the baseline file differs " \
                        "from the generated interface at the byte level. Regenerate the baselines."
                      end
    rescue StandardError => e
      # The check has already failed on bytes; surface why the explanation is missing.
      result[:diff] = "public-api-diff failed: #{e.message}"
    end

    result
  end

  # Pinned deliberately: the orb command defaults to 0.10.1, the release whose
  # SwiftInterfaceChangeConsolidator bug reported "no changes detected" for files that
  # differed. Fixed upstream in 0.11.0.
  PUBLIC_API_DIFF_VERSION = "0.12.0".freeze

  NO_CHANGES_MARKER = "✅ No changes detected".freeze

  CHANGES_HEADER_PATTERN = /^#\s.*\d+ public changes? detected/.freeze

  def validate_api_diff_inputs!(old_file, new_file)
    [old_file, new_file].each do |path|
      raise "Interface file not found: #{path}" unless File.exist?(path)
      raise "Interface file is empty: #{path}" if File.size(path).zero?
    end

    nil
  end

  # public-api-diff exits 0 for changes, for no changes, and even for a missing input file,
  # so its report is the only signal we have. Silence means the tool did not run, which is
  # not the same as the API being unchanged.
  def validate_api_diff_output!(output, old_file, new_file)
    report = output.to_s.encode("UTF-8", invalid: :replace, undef: :replace).strip

    raise "public-api-diff produced no output comparing #{old_file} to #{new_file}" if report.empty?
    return nil if report.include?(NO_CHANGES_MARKER)
    return nil if CHANGES_HEADER_PATTERN.match?(report)

    raise "Unrecognized public-api-diff output comparing #{old_file} to #{new_file}: #{report.lines.first.to_s.strip}"
  end

  def api_changes_reported?(output)
    !output.to_s.include?(NO_CHANGES_MARKER)
  end

  MERGE_BASE_SWIFTINTERFACE_DIR = "/tmp/merge-base-swiftinterface".freeze

  # The gate compares against the merge base rather than the PR's own baselines. Once an
  # author regenerates the baselines they match the generated interfaces exactly, and the
  # evidence of what the PR changed is gone.
  def resolve_merge_base(runner:)
    sha = runner.call("git", "merge-base", "origin/main", "HEAD").to_s.strip
    raise "Could not resolve the merge base with origin/main" if sha.empty?

    sha
  end

  def extract_baselines_at(sha, destination_dir, scheme, runner:)
    FileUtils.mkdir_p(destination_dir)
    prefix = api_file_prefix(scheme)

    PLATFORM_CHECKS.map do |platform|
      repo_path = "api/#{prefix}-api#{platform[:suffix]}.swiftinterface"
      content = runner.call("git", "show", "#{sha}:#{repo_path}").to_s

      raise "Baseline at #{sha}:#{repo_path} is missing or empty" if content.strip.empty?

      written = File.join(destination_dir, File.basename(repo_path))
      File.write(written, content)
      written
    end
  end

  ReportChange = Struct.new(:kind, :owner, :declaration, keyword_init: true)

  REPORT_TARGET_HEADING = /\A## `(.+)`\s*\z/.freeze
  REPORT_TYPE_HEADING = /\A### `(.+)`\s*\z/.freeze
  REPORT_KIND_HEADING = /\A#### .*\b(Added|Removed|Modified)\b\s*\z/.freeze
  REPORT_FENCE = /\A```/.freeze

  # The report nests members under their enclosing type, which is what lets us tell a case
  # added to an existing enum from a brand new enum that happens to have cases. A type
  # section only appears for a type present on both sides; a wholly new declaration sits
  # directly under the target heading, so its owner is nil.
  def parse_report(report)
    changes = []
    owner = nil
    kind = nil
    inside_block = false
    buffer = []

    report.to_s.each_line do |raw_line|
      line = raw_line.rstrip

      if REPORT_TARGET_HEADING.match?(line)
        owner = nil
        kind = nil
        next
      end

      if (match = REPORT_TYPE_HEADING.match(line))
        owner = match[1]
        kind = nil
        next
      end

      if (match = REPORT_KIND_HEADING.match(line))
        kind = match[1].downcase.to_sym
        next
      end

      if REPORT_FENCE.match?(line)
        if inside_block
          changes << ReportChange.new(kind: kind, owner: owner, declaration: buffer.join("\n").strip)
          buffer = []
          inside_block = false
        elsif kind
          inside_block = true
        end
        next
      end

      buffer << line if inside_block
    end

    if changes.empty? && api_changes_reported?(report)
      raise "public-api-diff reported changes but the report could not be parsed"
    end

    changes
  end

  ATTRIBUTE_ONLY_LINE = /\A(?:@\w+(?:\(.*\))?\s*)+\z/.freeze

  # A report block's literal first line is not always the significant one: the tool renders
  # each attribute on its own line above the declaration it belongs to (`@objc(RCFoo)` then
  # `case foo` on the next line), and a :modified block's fenced text opens with a literal
  # `// From` marker line before the actual declaration. Every caller that reasons about "what
  # declaration is this" (the enum-case prefix test, the type-name extractor, and a break's
  # displayed/dedup text) wants the line that actually names the symbol, not whichever text
  # happens to render first. Falls back to the raw first line if every line gets skipped
  # (an unexpected shape), so this never does worse than the un-skipped behavior.
  def significant_first_line(declaration)
    lines = declaration.to_s.lines.map(&:strip)
    significant = lines.drop_while { |line| line == "// From" || ATTRIBUTE_ONLY_LINE.match?(line) }

    (significant.first || lines.first).to_s
  end

  ATTRIBUTE_CHANGE_LINE = /\A-\s+(Added|Removed) attribute `([^`]*)`/.freeze

  # `unavailable` marks a declaration unusable immediately; `obsoleted` marks it unusable as of
  # a version that, for any shipping baseline, has already passed. Gaining either breaks
  # callers exactly like removing the declaration would. `deprecated` only warns, so it is
  # deliberately left out of this list: it is not breaking.
  BREAKING_ATTRIBUTE_ADDITION = /\b(?:unavailable|obsoleted)\b/.freeze

  # Gaining an attribute is usually additive (e.g. `@objc` newly added to a Swift-only member).
  # Losing one is not always additive: stripping `@objc` from a member on an Obj-C-exposed type
  # breaks every Obj-C caller (see this repo's Objective-C Compatibility guidance), so a
  # "Removed attribute" line must never be waved through here, whichever attribute it names.
  def modification_attribute_only?(declaration)
    lines = declaration.to_s.lines.map(&:strip)
    start = lines.index("Changes:")
    return false if start.nil?

    listed = lines[(start + 1)..].to_a.select { |line| line.start_with?("-") }
    return false if listed.empty?

    listed.all? { |line| non_breaking_attribute_addition?(line) }
  end

  def non_breaking_attribute_addition?(line)
    match = ATTRIBUTE_CHANGE_LINE.match(line)
    return false unless match

    verb, attribute = match[1], match[2]
    return false if verb == "Removed"

    !BREAKING_ATTRIBUTE_ADDITION.match?(attribute)
  end

  TYPE_DECLARATION = /\b(?:actor|class|enum|protocol|struct)\s+([A-Za-z_][A-Za-z0-9_]*)/.freeze

  def declaration_type_name(declaration)
    TYPE_DECLARATION.match(significant_first_line(declaration))&.captures&.first
  end

  # Strips `//` line comments and the contents of double-quoted string literals so prose
  # (e.g. an `@available(*, deprecated, message: "the enum Foo pattern...")` string) can't
  # masquerade as a declaration. Strings are neutralized first so a `//` inside one (a URL in
  # a deprecation message, say) isn't mistaken for a comment opener. String bodies are not
  # allowed to cross a newline, so an unbalanced quote can't swallow real declarations that
  # follow it. Block comments (`/* */`) are deliberately out of scope: real .swiftinterface
  # output doesn't use them, and we're not writing a Swift parser.
  def strip_comments_and_strings(contents)
    contents.gsub(/"(?:\\.|[^"\\\n])*"/, '""').gsub(%r{//[^\n]*}, '')
  end

  # The report says what changed and inside which type, but never what kind of type that is,
  # so the generated interface is the source of truth for enum versus protocol.
  def enclosing_type_kind(interface_path, type_name)
    name = type_name.to_s.split(".").last
    return nil if name.nil? || name.empty?

    contents = strip_comments_and_strings(File.read(interface_path))
    return :enum if contents.match?(/\benum\s+#{Regexp.escape(name)}\b/)
    return :protocol if contents.match?(/\bprotocol\s+#{Regexp.escape(name)}\b/)

    nil
  end

  # Matches `optional` only when it functions as a declaration modifier immediately preceding
  # the requirement's keyword (optionally after attributes like `@objc`), not merely anywhere
  # in the text, e.g. a parameter literally named `optional` or a doc comment mentioning it.
  # Failing to recognize a real `optional` modifier here would over-report, not under-report,
  # which is the safe direction for this gate.
  PROTOCOL_OPTIONAL_MODIFIER = /^\s*(?:@\w+(?:\([^)]*\))?\s*)*optional\s+(?:func|var|subscript|init)\b/.freeze

  def protocol_requirement_optional?(declaration)
    PROTOCOL_OPTIONAL_MODIFIER.match?(strip_comments_and_strings(declaration.to_s))
  end

  def breaking_changes(report, interface_path)
    changes = parse_report(report)
    new_type_names = changes.select { |change| change.kind == :added && change.owner.nil? }
                            .map { |change| declaration_type_name(change.declaration) }
                            .compact

    changes.each_with_object([]) do |change, breaks|
      first_line = significant_first_line(change.declaration)

      case change.kind
      when :removed
        breaks << { reason: :removed, owner: change.owner, declaration: first_line }
      when :modified
        next if modification_attribute_only?(change.declaration)

        breaks << { reason: :modified, owner: change.owner, declaration: first_line }
      when :added
        # A wholly new declaration breaks nothing, and neither does a member reported under a
        # type this same report introduces: match the owner in full, not by last component,
        # since a same-basename but differently-owned type (e.g. `Other.Config` alongside a
        # new top-level `Config`) must still be evaluated below. A nested member of a new type
        # reported with a dotted owner falls through to evaluation too; that only over-reports
        # (never under-reports), which `pr:breaking-api` exists to override.
        next if change.owner.nil?
        next if new_type_names.include?(change.owner)

        case enclosing_type_kind(interface_path, change.owner)
        when :enum
          breaks << { reason: :enum_case, owner: change.owner, declaration: first_line } if first_line.start_with?("case ")
        when :protocol
          next if protocol_requirement_optional?(change.declaration)

          breaks << { reason: :protocol_requirement, owner: change.owner, declaration: first_line }
        end
      end
    end
  end

  BREAKING_CHANGE_LABEL = "pr:breaking-api".freeze

  BREAK_REASONS = {
    removed: "removed",
    enum_case: "case added to an existing enum",
    protocol_requirement: "requirement added to an existing protocol",
    modified: "signature changed"
  }.freeze

  def gate_blocked?(breaks, labels)
    return false if breaks.empty?

    !Array(labels).include?(BREAKING_CHANGE_LABEL)
  end

  def print_breaking_summary(breaks, labels)
    return nil if breaks.empty?

    Fastlane::UI.error("=" * 60)
    Fastlane::UI.error("POTENTIAL BREAKING API CHANGES")
    Fastlane::UI.error("=" * 60)

    breaks.each do |change|
      owner = change[:owner] ? " in #{change[:owner]}" : ""
      Fastlane::UI.error("#{BREAK_REASONS.fetch(change[:reason], change[:reason])}#{owner}: #{change[:declaration]}")
    end

    Fastlane::UI.error("")
    if gate_blocked?(breaks, labels)
      Fastlane::UI.error("Add the #{BREAKING_CHANGE_LABEL} label if these changes are intentional.")
    else
      Fastlane::UI.important("Reported only: the #{BREAKING_CHANGE_LABEL} label is present.")
    end
    Fastlane::UI.error("=" * 60)

    nil
  end

  # `runner` exists so the tests can exercise this without a Swift toolchain or fastlane.
  def public_api_diff_report(tool:, old_file:, new_file:, target_name:, runner: nil)
    validate_api_diff_inputs!(old_file, new_file)

    runner ||= lambda do |*command|
      captured_output = nil
      begin
        Fastlane::Actions.sh(
          *command,
          log: false,
          error_callback: ->(sh_output) { captured_output = sh_output }
        )
      rescue StandardError => e
        # log: false keeps the raw report out of the CI log. If fastlane still raises
        # (rather than routing through error_callback), fold the captured output back in
        # so the failure is not just a bare exit status.
        raise "#{e.message}\n#{captured_output}".strip
      end
    end
    output = runner.call(
      tool, "swift-interface",
      "--old", old_file,
      "--new", new_file,
      "--target-name", target_name
    )
    # Sanitize before this string flows any further: it gets substring-matched and
    # stored in the result, not just validated, and invalid bytes would raise there too.
    output = output.to_s.encode("UTF-8", invalid: :replace, undef: :replace)

    validate_api_diff_output!(output, old_file, new_file)
    output
  end

  def print_failure_summary(failed_platforms)
    Fastlane::UI.error("=" * 60)
    Fastlane::UI.error("API CHANGES DETECTED")
    Fastlane::UI.error("=" * 60)
    Fastlane::UI.error("")
    Fastlane::UI.error("Platforms with changes: #{failed_platforms.map { |p| p[:platform] }.join(', ')}")
    Fastlane::UI.error("")

    failed_platforms.each do |platform|
      Fastlane::UI.error("-" * 40)
      Fastlane::UI.error(platform[:platform])
      Fastlane::UI.error("-" * 40)
      puts platform[:diff] if platform[:diff]
      Fastlane::UI.error("")
    end

    Fastlane::UI.error("=" * 60)
    Fastlane::UI.error("To fix: Update the baseline files if these changes are intentional.")
    Fastlane::UI.error("Run: bundle exec fastlane ios update_swiftinterface_baselines")
    Fastlane::UI.error("Optional: add scheme:RevenueCat or scheme:RevenueCatUI")
    Fastlane::UI.error("=" * 60)
  end
end
