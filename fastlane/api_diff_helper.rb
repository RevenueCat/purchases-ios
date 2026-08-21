# Helper module for API diff functionality
# Used by generate_swiftinterface and check_api_changes lanes

require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'open3'
require 'uri'

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

  # MODULES is ordered from the base module outwards: RevenueCatUI links RevenueCat, so building
  # the outermost requested module emits an interface for every module before it too. Verified
  # byte-identical against building each scheme on its own.
  def build_scheme_for(modules)
    MODULES.reverse.find { |name| Array(modules).include?(name) } ||
      raise("No buildable scheme covers #{Array(modules).join(', ')}")
  end

  BUILD_LOG_MUTEX = Mutex.new

  # The nine builds share one stdout, so a bare stream would interleave into something unreadable.
  # Tagging each line with the SDK keeps the log greppable per build, and streaming rather than
  # buffering keeps output flowing so CircleCI's no-output timeout never fires. The mutex holds a
  # whole line together: xcodebuild echoes multi-kilobyte compiler invocations, and a write that
  # large is not atomic.
  def stream_build_output(sdk, output)
    output.each_line do |line|
      BUILD_LOG_MUTEX.synchronize do
        $stdout.puts("[#{sdk}] #{line.chomp}")
        $stdout.flush
      end
    end
  end

  # One platform runs per thread, so this avoids fastlane's `sh` and `Dir.chdir`: both mutate
  # process-global state (the default encoding and the working directory) that the other builds
  # share. Failures come back as a result rather than an exception for the same reason: raising
  # inside a thread only surfaces wherever its value happens to be read. Every message names the
  # SDK because PLATFORMS reuses one platform label for a device and its simulator.
  def build_swiftinterface(platform_config, scheme:, modules:, project_root:, output_dir:)
    sdk = platform_config[:sdk]
    # Concurrent builds cannot share a derived data directory.
    derived_data = "#{project_root}/.build-#{scheme}-#{sdk}"

    sdk_path, status = Open3.capture2e("xcrun", "--sdk", sdk, "--show-sdk-path")
    return { success: false, error: "xcrun failed for #{sdk}: #{sdk_path.strip}" } unless status.success?

    Fastlane::UI.message("Building #{scheme} for #{platform_config[:platform]} (#{sdk})...")

    build_status = Open3.popen2e(
      "xcodebuild", "clean", "build",
      "-workspace", ".",
      "-scheme", scheme,
      "-derivedDataPath", derived_data,
      "-configuration", "Release",
      "-sdk", sdk_path.strip,
      "-destination", platform_config[:destination],
      "BUILD_LIBRARY_FOR_DISTRIBUTION=YES",
      chdir: project_root
    ) do |stdin, output, wait_thread|
      stdin.close
      stream_build_output(sdk, output)
      wait_thread.value
    end

    unless build_status.success?
      return {
        success: false,
        error: "xcodebuild failed for #{scheme} on #{platform_config[:platform]} (#{sdk})"
      }
    end

    missing = []
    Array(modules).each do |module_name|
      found = find_swiftinterface_file(derived_data, sdk, module_name).first

      if found.nil?
        missing << module_name
      else
        FileUtils.cp(found, "#{output_dir}/#{module_name}#{platform_config[:suffix]}.swiftinterface")
      end
    end

    if missing.any?
      return {
        success: false,
        error: "Could not find #{missing.join(', ')} swiftinterface for #{platform_config[:platform]} (#{sdk})"
      }
    end

    Fastlane::UI.success(
      "Generated #{Array(modules).join(', ')} #{platform_config[:platform]} (#{sdk}) swiftinterface"
    )

    { success: true }
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
      # Already failed on bytes; surface why the explanation is missing.
      result[:diff] = "public-api-diff failed: #{e.message}"
    end

    result
  end

  # 0.12.0
  PUBLIC_API_DIFF_REF = "06620ffe614773a43102ab8052077ae463908b78".freeze

  NO_CHANGES_MARKER = "✅ No changes detected".freeze

  CHANGES_HEADER_PATTERN = /^#\s.*\d+ public changes? detected/.freeze

  def validate_api_diff_inputs!(old_file, new_file)
    [old_file, new_file].each do |path|
      raise "Interface file not found: #{path}" unless File.exist?(path)
      raise "Interface file is empty: #{path}" if File.size(path).zero?
    end

    nil
  end

  # The tool exits 0 even for a missing input file, so silence means it did not run.
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

  # The PR's own baselines match the generated files once regenerated, erasing the evidence.
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

  # A type section only appears for a type on both sides, so a new declaration has no owner.
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

  # Attributes render on their own line, and a modification opens with `// From`.
  def significant_first_line(declaration)
    lines = declaration.to_s.lines.map(&:strip)
    significant = lines.drop_while { |line| line == "// From" || ATTRIBUTE_ONLY_LINE.match?(line) }

    (significant.first || lines.first).to_s
  end

  ATTRIBUTE_CHANGE_LINE = /\A-\s+(Added|Removed) attribute `([^`]*)`/.freeze

  # An allowlist, so an attribute nobody thought about counts as breaking rather than slipping
  # through: @MainActor constrains every caller, and a new @available floor drops platforms.
  NON_BREAKING_ATTRIBUTE_ADDITIONS = [
    /\A@objc\b/,
    /\A@discardableResult\b/,
    /\A@inlinable\b/,
    /\A@available\(\s*\*\s*,\s*deprecated\b/
  ].freeze

  # Stripping `@objc` breaks every Obj-C caller, so a removal is never waved through.
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

    NON_BREAKING_ATTRIBUTE_ADDITIONS.any? { |allowed| allowed.match?(attribute) }
  end

  TYPE_DECLARATION = /\b(?:actor|class|enum|protocol|struct)\s+([A-Za-z_][A-Za-z0-9_]*)/.freeze

  def declaration_type_name(declaration)
    TYPE_DECLARATION.match(significant_first_line(declaration))&.captures&.first
  end

  # Keeps prose in strings and comments from passing as a declaration.
  def strip_comments_and_strings(contents)
    contents.gsub(/"(?:\\.|[^"\\\n])*"/, '""').gsub(%r{//[^\n]*}, '')
  end

  # The report never says what kind of type an owner is, so the interface decides.
  def enclosing_type_kind(interface_path, type_name)
    name = type_name.to_s.split(".").last
    return nil if name.nil? || name.empty?

    contents = strip_comments_and_strings(File.read(interface_path))
    return :enum if contents.match?(/\benum\s+#{Regexp.escape(name)}\b/)
    return :protocol if contents.match?(/\bprotocol\s+#{Regexp.escape(name)}\b/)

    nil
  end

  # Only as a modifier, not a parameter named `optional`.
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
        # By last component a new top-level `Config` would mask a break on `Other.Config`.
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

  API_DIFF_COMMENT_MARKER = "<!-- api-diff-report -->".freeze

  def api_diff_section_open(module_name)
    "<!-- api-diff:#{module_name} -->"
  end

  def api_diff_section_close(module_name)
    "<!-- /api-diff:#{module_name} -->"
  end

  # The comment carries one section per module, so writing one must not drop the others.
  def merge_api_diff_comment(existing_body, module_name, section)
    open_tag = api_diff_section_open(module_name)
    close_tag = api_diff_section_close(module_name)
    body = existing_body.to_s

    unless body.include?(API_DIFF_COMMENT_MARKER)
      return "#{API_DIFF_COMMENT_MARKER}\n## Public API changes\n\n#{section}\n"
    end

    if body.include?(open_tag) && body.include?(close_tag)
      body.sub(/#{Regexp.escape(open_tag)}.*?#{Regexp.escape(close_tag)}/m, section)
    else
      "#{body.rstrip}\n\n#{section}\n"
    end
  end

  def announced_marker(fingerprint)
    "<!-- api-diff-announced:#{fingerprint} -->"
  end

  def announcement_fingerprint(message)
    Digest::SHA256.hexdigest(message.to_s)[0, 12]
  end

  ANNOUNCED_MARKER_PATTERN = /<!-- api-diff-announced:([0-9a-f]+) -->/.freeze

  # The marker records the last summary that reached the channel, which a run with nothing to
  # announce, or one whose post failed, did not change.
  def announced_fingerprint_in(comment_body, module_name)
    open_tag = Regexp.escape(api_diff_section_open(module_name))
    close_tag = Regexp.escape(api_diff_section_close(module_name))
    section = comment_body.to_s[/#{open_tag}.*?#{close_tag}/m]

    section && ANNOUNCED_MARKER_PATTERN.match(section)&.captures&.first
  end

  # The comment body is only read for :unknown, so the caller passes a block that fetches it.
  def already_announced?(state, fingerprint)
    return true if state == :same
    return false unless state == :unknown

    yield.to_s.include?(announced_marker(fingerprint))
  end

  def comment_needed?(reports_by_target, breaks, existing_body, module_name)
    return true if breaks.any? || changed_modules(reports_by_target).any?

    existing_body.to_s.include?(api_diff_section_open(module_name))
  end

  def api_diff_comment_section(module_name, reports_by_target, breaks, labels, notice: nil, announced_fingerprint: nil)
    inner = api_diff_comment_body(reports_by_target, breaks, labels, heading: "### #{module_name}", notice: notice)
    parts = [api_diff_section_open(module_name), inner]
    parts << announced_marker(announced_fingerprint) if announced_fingerprint

    (parts << api_diff_section_close(module_name)).join("\n")
  end

  def api_diff_comment_body(reports_by_target, breaks, labels, heading: nil, notice: nil)
    lines = heading ? [heading] : [API_DIFF_COMMENT_MARKER, "## Public API changes"]

    unless notice.to_s.empty?
      lines << ""
      lines << ":warning: #{notice}"
    end

    if breaks.any?
      lines << ""
      lines << (gate_blocked?(breaks, labels) ? "### :warning: Potential breaking changes" : "### :warning: Potential breaking changes (allowed by label)")
      breaks.each do |change|
        owner = change[:owner] ? " in `#{change[:owner]}`" : ""
        lines << "- **#{BREAK_REASONS.fetch(change[:reason], change[:reason])}**#{owner}: `#{change[:declaration]}`"
      end
      lines << ""
      lines << "Add the `#{BREAKING_CHANGE_LABEL}` label if these are intentional." if gate_blocked?(breaks, labels)
    end

    changed = reports_by_target.reject { |_target, report| report.nil? || !api_changes_reported?(report) }

    if changed.empty?
      lines << ""
      lines << "No public API changes."
    else
      # Nine identical per-platform reports collapse into one section.
      changed.group_by { |_target, report| strip_target_headings(report) }.each do |_body, group|
        targets = group.map(&:first)
        lines << ""
        lines << "<details><summary>#{targets.first.split(' ').first} on #{describe_targets(targets)}</summary>"
        lines << ""
        lines << group.first.last.strip
        lines << ""
        lines << "</details>"
      end
    end

    lines.join("\n")
  end

  # Target names differ per platform, so neutralise them before comparing reports.
  def strip_target_headings(report)
    report.to_s.gsub(/^#+ `[^`]*`\s*$/, "").gsub(/\*\*Analyzed targets:\*\*.*$/, "").strip
  end

  def describe_targets(targets)
    platforms = targets.map { |target| target.split(" ", 2).last }
    return "all platforms" if platforms.count >= PLATFORM_CHECKS.count

    platforms.join(", ")
  end

  # Counting reports would count platforms, not API.
  def added_declarations(reports_by_target)
    reports_by_target.values.compact.flat_map do |report|
      next [] unless api_changes_reported?(report)

      parse_report(report).select { |change| change.kind == :added }
                          .map { |change| significant_first_line(change.declaration) }
    end.reject { |declaration| declaration.to_s.empty? }.uniq.sort
  end

  SDK_PLATFORM_LABEL = "iOS :ios:".freeze

  # last_announcement matches on this, so the headline and the dedup key cannot drift apart.
  def announcement_identity(modules)
    [SDK_PLATFORM_LABEL, *modules.map { |name| "`#{name}`" }].join(" · ")
  end

  SLACK_DECLARATION_LIMIT = 10

  # Slack stops wrapping code blocks past this; the full text is in the PR comment.
  SLACK_DECLARATION_WIDTH = 160

  def slack_declaration_block(declarations)
    shown = declarations.first(SLACK_DECLARATION_LIMIT).map do |declaration|
      declaration.length > SLACK_DECLARATION_WIDTH ? "#{declaration[0, SLACK_DECLARATION_WIDTH - 1]}…" : declaration
    end
    remaining = declarations.count - shown.count
    shown << "…and #{remaining} more" if remaining.positive?

    "```\n#{shown.join("\n")}\n```"
  end

  # Target names are "#{scheme} #{platform}", built by the check_api_changes lane.
  def changed_modules(reports_by_target)
    reports_by_target.select { |_target, report| api_changes_reported?(report) }
                     .keys.map { |target| target.split(" ").first }.uniq.sort
  end

  # Not all breaks are removals, so each carries its reason; additions match the `+` Android uses.
  # An enum case or protocol requirement is both an addition and a break, so it is listed once.
  def slack_declaration_lines(breaks, new_declarations)
    break_lines = breaks.map do |change|
      owner = change[:owner] ? " in #{change[:owner]}" : ""
      "- #{BREAK_REASONS.fetch(change[:reason], change[:reason])}#{owner}: #{change[:declaration]}"
    end
    broken = breaks.map { |change| change[:declaration] }

    break_lines + (new_declarations - broken).map { |declaration| "+ #{declaration}" }
  end

  def slack_summary(breaks, labels, source:, new_declarations: [], modules: [])
    headline = if breaks.any?
                 gate_blocked?(breaks, labels) ? ":warning: *Breaking public API changes*" : ":warning: *Breaking public API changes* (allowed by label)"
               else
                 ":sparkles: *New public API*"
               end
    headline = [headline, announcement_identity(modules)].join(" · ")

    lines = [headline]
    lines << source unless source.to_s.empty?

    counts = []
    counts << "#{breaks.count} potential break#{'s' if breaks.count != 1}" if breaks.any?
    counts << "#{new_declarations.count} new declaration#{'s' if new_declarations.count != 1}" if new_declarations.any?
    lines << counts.join(", ") if counts.any?

    declaration_lines = slack_declaration_lines(breaks, new_declarations)
    lines << slack_declaration_block(declaration_lines) if declaration_lines.any?

    lines.join("\n")
  end


  SLACK_UNREACHABLE_NOTICE = "No Slack credentials were reachable, so this change was not announced in the SDK API feed.".freeze

  def slack_post_request(message, webhook_url: nil, bot_token: nil, channel: nil)
    unless webhook_url.to_s.empty?
      return {
        url: webhook_url,
        headers: { "Content-Type" => "application/json" },
        body: { text: message }
      }
    end

    return nil if bot_token.to_s.empty? || channel.to_s.empty?

    {
      url: "https://slack.com/api/chat.postMessage",
      headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{bot_token}" },
      body: { channel: channel, text: message }
    }
  end

  SLACK_HISTORY_LIMIT = 100

  # conversations.history takes a channel ID, never a `#name`.
  CHANNEL_ID = /\A[CGD][A-Z0-9]+\z/.freeze

  def slack_history_request(channel, bot_token:, limit: SLACK_HISTORY_LIMIT)
    {
      url: "https://slack.com/api/conversations.history?channel=#{channel}&limit=#{limit}",
      headers: { "Authorization" => "Bearer #{bot_token}" }
    }
  end

  def recent_slack_messages(request, getter: nil)
    getter ||= ->(url, headers) { Net::HTTP.get_response(URI.parse(url), headers) }

    response = getter.call(request[:url], request[:headers])
    raise "Slack returned #{response.code}: #{response.body}" unless (200..299).cover?(response.code.to_i)

    parsed = JSON.parse(response.body.to_s)
    raise "Slack rejected conversations.history: #{parsed['error']}" unless parsed["ok"]

    parsed["messages"].to_a.map { |message| message["text"].to_s }
  end

  # conversations.history answers newest first, so the first match is the channel's last word. The
  # trailing backtick in the identity keeps `RevenueCat` from matching `RevenueCatUI`.
  def last_announcement(texts, source, modules)
    return nil if source.to_s.empty?

    identity = announcement_identity(modules)

    texts.find { |text| text.include?(source) && text.include?(identity) }
  end

  # A webhook cannot read the channel, and conversations.history needs an ID rather than a name.
  # Returns [:same | :different | :unknown, why_unknown].
  def announcement_state(message, bot_token:, channel:, source:, modules:, getter: nil)
    return [:unknown, "no bot token, so the SDK API feed cannot be read"] if bot_token.to_s.empty?

    unless CHANNEL_ID.match?(channel.to_s)
      return [:unknown, "#{channel} is a channel name, and conversations.history needs the channel ID"]
    end

    request = slack_history_request(channel, bot_token: bot_token)
    last = last_announcement(recent_slack_messages(request, getter: getter), source, modules)
    return [:unknown, nil] if last.nil?

    [last == message ? :same : :different, nil]
  rescue StandardError => e
    [:unknown, e.message]
  end

  # `poster` exists so the tests can exercise the response handling without a network.
  def post_slack_message(request, poster: nil)
    poster ||= ->(url, body, headers) { Net::HTTP.post(URI.parse(url), body, headers) }

    response = poster.call(request[:url], request[:body].to_json, request[:headers])
    raise "Slack returned #{response.code}: #{response.body}" unless (200..299).cover?(response.code.to_i)

    # chat.postMessage answers 200 with ok:false, and a webhook answers with the bare string "ok".
    parsed = begin
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      nil
    end
    raise "Slack rejected the message: #{parsed['error']}" if parsed.is_a?(Hash) && parsed["ok"] == false

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
        # log: false keeps the report out of the CI log; the callback keeps it in the error.
        raise "#{e.message}\n#{captured_output}".strip
      end
    end
    output = runner.call(
      tool, "swift-interface",
      "--old", old_file,
      "--new", new_file,
      "--target-name", target_name
    )
    # Sanitised here because the value is substring-matched and stored, not just validated.
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
