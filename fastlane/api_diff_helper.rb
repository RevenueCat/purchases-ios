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

  ATTRIBUTE_CHANGE_LINE = /\A-\s+(Added|Removed) attribute\b/.freeze

  # Gaining or losing an attribute rewrites a declaration without breaking callers.
  def modification_attribute_only?(declaration)
    lines = declaration.to_s.lines.map(&:strip)
    start = lines.index("Changes:")
    return false if start.nil?

    listed = lines[(start + 1)..].to_a.select { |line| line.start_with?("-") }
    return false if listed.empty?

    listed.all? { |line| ATTRIBUTE_CHANGE_LINE.match?(line) }
  end

  TYPE_DECLARATION = /\b(?:actor|class|enum|protocol|struct)\s+([A-Za-z_][A-Za-z0-9_]*)/.freeze

  def declaration_type_name(declaration)
    TYPE_DECLARATION.match(declaration.to_s.lines.first.to_s)&.captures&.first
  end

  # The report says what changed and inside which type, but never what kind of type that is,
  # so the generated interface is the source of truth for enum versus protocol.
  def enclosing_type_kind(interface_path, type_name)
    name = type_name.to_s.split(".").last
    return nil if name.nil? || name.empty?

    contents = File.read(interface_path)
    return :enum if contents.match?(/\benum\s+#{Regexp.escape(name)}\b/)
    return :protocol if contents.match?(/\bprotocol\s+#{Regexp.escape(name)}\b/)

    nil
  end

  def breaking_changes(report, interface_path)
    changes = parse_report(report)
    new_type_names = changes.select { |change| change.kind == :added && change.owner.nil? }
                            .map { |change| declaration_type_name(change.declaration) }
                            .compact

    changes.each_with_object([]) do |change, breaks|
      first_line = change.declaration.to_s.lines.first.to_s.strip

      case change.kind
      when :removed
        breaks << { reason: :removed, owner: change.owner, declaration: first_line }
      when :modified
        next if modification_attribute_only?(change.declaration)

        breaks << { reason: :modified, owner: change.owner, declaration: first_line }
      when :added
        # A wholly new declaration breaks nothing, and neither does a member of a type this
        # same report introduces.
        next if change.owner.nil?
        next if new_type_names.include?(change.owner.split(".").last)

        case enclosing_type_kind(interface_path, change.owner)
        when :enum
          breaks << { reason: :enum_case, owner: change.owner, declaration: first_line } if first_line.start_with?("case ")
        when :protocol
          next if change.declaration.include?("optional ")

          breaks << { reason: :protocol_requirement, owner: change.owner, declaration: first_line }
        end
      end
    end
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
