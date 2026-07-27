# Helper module for API diff functionality
# Used by generate_swiftinterface and check_api_changes lanes

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

  def run_api_diff(old_file, new_file, platform_name)
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
    else
      Fastlane::UI.error("❌ API changes detected for #{platform_name}")
      result[:diff] = `diff -u "#{old_file}" "#{new_file}"`.encode('UTF-8', invalid: :replace, undef: :replace)
    end

    result
  end

  # Every changed line in a swiftinterface is treated as API except known noise, so a
  # declaration form we didn't anticipate still gets reported.
  # Comments cover the compiler-version header, which churns on every Xcode bump.
  IGNORED_LINE_PREFIXES = ["//", "import ", "#if", "#else", "#elseif", "#endif"].freeze

  # Accessors and lone punctuation travel with the declaration that owns them.
  ACCESSOR_OR_PUNCTUATION_LINE = /\A(?:get|set|_modify|_read|yield|mutating get|nonmutating set|[{}()\[\],;:]+)\z/.freeze

  # A single attribute, with its optional argument list.
  ATTRIBUTE_PATTERN = /\A@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s*/.freeze

  DIFF_METADATA_PREFIXES = [
    "+++", "---", "@@", "index ", "new file", "deleted file", "similarity ", "rename ", "Binary "
  ].freeze

  # Declarations listed per module before the Slack message truncates.
  MAX_DECLARATIONS_PER_MODULE = 10

  def module_for_api_file(path)
    case File.basename(path.to_s)
    when /\Arevenuecatui-api/ then "RevenueCatUI"
    when /\Arevenuecat-api/ then "RevenueCat"
    end
  end

  def api_declaration?(line)
    stripped = line.strip
    return false if stripped.empty?
    return false if IGNORED_LINE_PREFIXES.any? { |prefix| stripped.start_with?(prefix) }
    return false if ACCESSOR_OR_PUNCTUATION_LINE.match?(stripped)

    !attributes_only?(stripped)
  end

  # True for lines that are nothing but attributes, e.g. a standalone `@available(...)`.
  # `@objc public func foo()` keeps the declaration after the attribute, so it isn't one.
  def attributes_only?(line)
    rest = line
    matched = false

    while (match = ATTRIBUTE_PATTERN.match(rest))
      rest = match.post_match
      matched = true
    end

    matched && rest.empty?
  end

  # Added lines with their position in the new file, per api/ file, so a declaration can
  # later be attributed to whatever encloses it.
  def added_lines_by_file(diff_text)
    added = {}
    current_path = nil
    line_number = 0

    diff_text.to_s.each_line do |line|
      if line.start_with?("diff --git ")
        current_path = line.split(" ").last.to_s.sub(%r{\Ab/}, "").chomp
        next
      end

      next if current_path.nil?

      if (hunk = line.match(/\A@@ -\d+(?:,\d+)? \+(\d+)/))
        line_number = hunk[1].to_i
        next
      end

      next if DIFF_METADATA_PREFIXES.any? { |prefix| line.start_with?(prefix) }

      if line.start_with?("+")
        (added[current_path] ||= []) << { line_number: line_number, text: line[1..].to_s.chomp }
        line_number += 1
      elsif line.start_with?(" ")
        line_number += 1
      end
    end

    added
  end

  # The declaration a line sits inside, found by walking up to the closest line indented
  # less than it. Nested types resolve to the type that owns them, not the outermost one.
  def enclosing_declaration(lines, line_number)
    index = line_number - 1
    return nil if index <= 0 || index >= lines.length

    indentation = indentation_of(lines[index])

    (index - 1).downto(0) do |candidate_index|
      candidate = lines[candidate_index]
      next unless api_declaration?(candidate)
      next unless indentation_of(candidate) < indentation

      return candidate.strip
    end

    nil
  end

  def indentation_of(line)
    line[/\A[ \t]*/].length
  end

  def declaration_owner(declaration, keyword)
    declaration[/\b#{keyword}\s+([A-Za-z_][A-Za-z0-9_]*)/, 1]
  end

  # Additions that can break existing code even though nothing was removed: a case added to
  # an existing public enum breaks exhaustive switches, and a requirement added to an
  # existing public protocol breaks outside conformers. Both are fine when the enclosing
  # type is itself new, hence the check against everything the diff adds.
  #
  # Takes a block that returns the new version of an api/ file as an array of lines.
  def breaking_additions(diff_text)
    added_declarations = parse_api_diff(diff_text).transform_values { |changes| changes[:added] }
    breaks = {}

    added_lines_by_file(diff_text).each do |path, lines|
      module_name = module_for_api_file(path)
      next if module_name.nil?

      new_file_lines = yield(path)

      lines.each do |added_line|
        declaration = added_line[:text].strip
        next unless api_declaration?(declaration)

        owner = enclosing_declaration(new_file_lines, added_line[:line_number])
        next if owner.nil?
        # The whole type is new, so nothing existing can break.
        next if added_declarations.fetch(module_name, []).include?(owner)

        kind = breaking_addition_kind(declaration, owner)
        next if kind.nil?

        (breaks[module_name] ||= []) << {
          kind: kind,
          owner: declaration_owner(owner, kind == :enum_case ? "enum" : "protocol"),
          text: declaration
        }
      end
    end

    breaks.each_value(&:uniq!)
    breaks
  end

  def breaking_addition_kind(declaration, owner)
    return :enum_case if owner.match?(/\benum\b/) && declaration.start_with?("case ")
    # An optional Objective-C requirement doesn't force conformers to do anything.
    return :protocol_requirement if owner.match?(/\bprotocol\b/) && !declaration.match?(/\boptional\b/)

    nil
  end

  # Groups a `git diff` over api/*.swiftinterface into added/removed declarations per
  # module. The same declaration shows up in every platform file, so results are
  # deduplicated and indentation is stripped.
  def parse_api_diff(diff_text)
    changes = {}
    current_module = nil

    diff_text.to_s.each_line do |line|
      if line.start_with?("diff --git ")
        current_module = module_for_api_file(line.split(" ").last.to_s.sub(%r{\Ab/}, ""))
        next
      end

      next if current_module.nil?
      next if DIFF_METADATA_PREFIXES.any? { |prefix| line.start_with?(prefix) }

      bucket = if line.start_with?("+")
                 :added
               elsif line.start_with?("-")
                 :removed
               end
      next if bucket.nil?

      declaration = line[1..].to_s.strip
      next unless api_declaration?(declaration)

      changes[current_module] ||= { added: [], removed: [] }
      changes[current_module][bucket] << declaration
    end

    changes.each_value do |module_changes|
      module_changes[:added].uniq!
      module_changes[:removed].uniq!
    end

    changes
  end

  # A declaration that shows up as both added and removed is a move or a re-indent in
  # some platform file, not an API change, so both sides cancel out.
  #
  # Gaining or losing an attribute rewrites the line without removing the declaration
  # (exposing something to Objective-C with @objc, deprecating it with @available), so the
  # removal is dropped while the new form is still announced.
  def new_api_changes(diff_text)
    parse_api_diff(diff_text).each_with_object({}) do |(module_name, module_changes), result|
      added = module_changes[:added] - module_changes[:removed]
      removed = module_changes[:removed] - module_changes[:added]

      added_without_attributes = added.map { |declaration| declaration_without_attributes(declaration) }
      removed = removed.reject do |declaration|
        added_without_attributes.include?(declaration_without_attributes(declaration))
      end

      next if added.empty? && removed.empty?

      result[module_name] = { new: added.sort, removed: removed.sort }
    end
  end

  def declaration_without_attributes(declaration)
    rest = declaration

    while (match = ATTRIBUTE_PATTERN.match(rest))
      rest = match.post_match
    end

    rest
  end

  def new_api?(changes_by_module)
    changes_by_module.any? { |_, changes| !changes[:new].empty? }
  end

  def pull_request_link(number:, title:, repo_url:)
    "<#{repo_url}/pull/#{number}|##{number}> #{title}".strip
  end

  # Slack link to the PR that introduced the change, falling back to the commit when the
  # subject has no PR number (only squash merges carry one).
  def source_link(subject:, sha:, repo_url:)
    pr_number = subject[/\(#(\d+)\)\s*\z/, 1]
    return "<#{repo_url}/commit/#{sha}|#{sha}> #{subject}" if pr_number.nil?

    "<#{repo_url}/pull/#{pr_number}|##{pr_number}> #{subject.sub(/\s*\(#\d+\)\s*\z/, '')}"
  end

  # A pull request notification and the post-merge one can both fire for the same API, so
  # the headline says which moment this is. A change that only breaks leads with the
  # warning instead of announcing new API that isn't there.
  HEADLINES = {
    up_for_review: { new_api: "New public API up for review", breaks: "Potential API breaks up for review" },
    landed: { new_api: "New public API landed on `main`", breaks: "Potential API breaks landed on `main`" }
  }.freeze

  HEADLINE_ICONS = { new_api: ":sparkles:", breaks: ":warning:" }.freeze

  def reportable?(changes_by_module, breaks_by_module = {})
    new_api?(changes_by_module) || !break_entries(changes_by_module, breaks_by_module).empty?
  end

  # Removals and breaking additions, as the lines they'll take in the message.
  def break_entries(changes_by_module, breaks_by_module = {})
    entries = {}

    changes_by_module.each do |module_name, changes|
      changes[:removed].each do |declaration|
        (entries[module_name] ||= []) << "- removed: #{declaration}"
      end
    end

    breaks_by_module.each do |module_name, module_breaks|
      module_breaks.each do |module_break|
        label = module_break[:kind] == :enum_case ? "new case in" : "new requirement in"
        (entries[module_name] ||= []) << "+ #{label} #{module_break[:owner]}: #{module_break[:text]}"
      end
    end

    entries
  end

  def api_report_message(changes_by_module, breaks_by_module: {}, source: nil, status: :up_for_review)
    new_api_by_module = changes_by_module.reject { |_, changes| changes[:new].empty? }
    breaks = break_entries(changes_by_module, breaks_by_module)
    kind = new_api_by_module.empty? ? :breaks : :new_api

    module_names = (new_api_by_module.keys + breaks.keys).uniq.sort
    lines = ["#{HEADLINE_ICONS.fetch(kind)} *#{HEADLINES.fetch(status).fetch(kind)}* in #{module_names.join(', ')}"]
    lines << source unless source.to_s.empty?

    new_api_by_module.keys.sort.each do |module_name|
      lines << ""
      lines << "*#{module_name}*"
      lines << declaration_block(new_api_by_module[module_name][:new].map { |declaration| "+ #{declaration}" })
    end

    unless breaks.empty?
      lines << ""
      lines << ":warning: *Potential API breaks*"

      breaks.keys.sort.each do |module_name|
        lines << "*#{module_name}*"
        lines << declaration_block(breaks[module_name])
      end
    end

    lines.join("\n")
  end

  # Either an incoming webhook, which carries its own channel, or a bot token with an
  # explicit channel, so the notification can use whichever Slack credential the CI system
  # already has. Returns nil when neither is configured.
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

  def declaration_block(entries)
    shown = entries.first(MAX_DECLARATIONS_PER_MODULE)
    remaining = entries.count - shown.count
    shown += ["... and #{remaining} more"] if remaining > 0

    "```\n#{shown.join("\n")}\n```"
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
