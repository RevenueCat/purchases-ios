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

  # SPI groups whose declarations are considered consumer-facing for the purposes
  # of the public-enums policy. Internal SPI is intentionally excluded.
  CONSUMER_FACING_SPI_GROUPS = %w[Experimental].freeze

  PRIVATE_SWIFTINTERFACE_SUFFIX = ".private.swiftinterface".freeze

  module_function

  def api_file_prefix(scheme)
    scheme.downcase
  end

  # Path (within the repo) of the public-enums allowlist for a given module.
  def public_enums_allowlist_path(scheme)
    "../api/#{api_file_prefix(scheme)}-public-enums-allowlist.txt"
  end

  def swiftinterface_pattern_for_sdk(sdk, module_name, suffix: ".swiftinterface")
    case sdk
    when "iphonesimulator"
      "**/Release-iphonesimulator/**/Objects-normal/**/#{module_name}#{suffix}"
    when "iphoneos"
      "**/Release-iphoneos/**/Objects-normal/**/#{module_name}#{suffix}"
    when "macosx"
      "**/Release/**/Objects-normal/**/#{module_name}#{suffix}"
    when "watchsimulator"
      "**/Release-watchsimulator/**/Objects-normal/**/#{module_name}#{suffix}"
    when "watchos"
      "**/Release-watchos/**/Objects-normal/**/#{module_name}#{suffix}"
    when "appletvsimulator"
      "**/Release-appletvsimulator/**/Objects-normal/**/#{module_name}#{suffix}"
    when "appletvos"
      "**/Release-appletvos/**/Objects-normal/**/#{module_name}#{suffix}"
    when "xrsimulator"
      "**/Release-xrsimulator/**/Objects-normal/**/#{module_name}#{suffix}"
    when "xros"
      "**/Release-xros/**/Objects-normal/**/#{module_name}#{suffix}"
    else
      "**/#{module_name}#{suffix}"
    end
  end

  def find_swiftinterface_file(derived_data_dir, sdk, module_name)
    pattern = swiftinterface_pattern_for_sdk(sdk, module_name)
    Dir.glob("#{derived_data_dir}/#{pattern}")
       .reject { |path| path.include?("private") }
  end

  # Locates the .private.swiftinterface file emitted alongside the public one
  # when the module is built with library evolution. Returns the matching
  # paths for the given SDK and module.
  def find_private_swiftinterface_file(derived_data_dir, sdk, module_name)
    pattern = swiftinterface_pattern_for_sdk(
      sdk,
      module_name,
      suffix: PRIVATE_SWIFTINTERFACE_SUFFIX
    )
    Dir.glob("#{derived_data_dir}/#{pattern}")
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

  # ---------------------------------------------------------------------------
  # Public-enums policy
  # ---------------------------------------------------------------------------

  # Parses a .private.swiftinterface file and returns the sorted list of
  # consumer-facing enum declarations as fully-qualified names within the
  # module (e.g. "AppleReceipt.Environment").
  #
  # "Consumer-facing" means: declarations that are either fully public or
  # carry an SPI attribute whose group is in CONSUMER_FACING_SPI_GROUPS.
  # Internal SPI declarations (e.g. @_spi(Internal)) are excluded.
  def extract_consumer_facing_enums(file_path, module_name)
    enums = []
    context_stack = []  # entries: { name:, opening_depth: }
    brace_depth = 0
    pending_attrs = +""

    standalone_attrs_re = /\A(?:@[\w_]+(?:\([^)]*\))?\s*)+\z/
    type_decl_re = /
      \A
      (?<prefix>(?:[\w@_]+(?:\([^)]*\))?\s+)*)
      (?<kind>extension|class|struct|enum|actor|protocol)\b
      \s+
      (?<rest>.*)
      \z
    /x

    File.foreach(file_path, chomp: true) do |raw_line|
      line = raw_line.strip
      next if line.empty?
      next if line.start_with?("//")
      next if line.start_with?("#") # skip preprocessor lines

      # Lines that are only attributes (e.g. a bare `@_spi(Experimental)` or
      # multiple `@available(...)` clauses) get accumulated and prepended to
      # the next non-attribute line so we can detect their SPI group there.
      if standalone_attrs_re.match?(line)
        pending_attrs << " " << line
        next
      end

      combined = "#{pending_attrs} #{line}".strip
      pending_attrs.clear

      spi_group = combined[/@_spi\(\s*(\w+)\s*\)/, 1]

      consumed_kind = nil
      consumed_name = nil

      if (m = type_decl_re.match(combined))
        kind = m[:kind]
        rest = m[:rest].strip

        name =
          if kind == "extension"
            # Extension targets look like:
            #   "RevenueCat.AppleReceipt {"
            #   "RevenueCat.AppleReceipt : Swift.Sendable {"
            #   "RevenueCat.PurchasesError.Code : Swift.CaseIterable {"
            full = rest.split(/[:{]| where /).first.to_s.strip
            if full.start_with?("#{module_name}.")
              full[(module_name.length + 1)..]
            else
              full
            end
          else
            # Type declarations look like:
            #   "Foo {", "Foo : Swift.Int {", "Foo<T> : Bar where T: ... {"
            rest.split(/[<\s:{]/).first.to_s
          end

        next if name.nil? || name.empty?

        consumed_kind = kind
        consumed_name = name

        if kind == "enum" && consumer_facing_spi?(spi_group)
          fq = (context_stack.map { |c| c[:name] } + [consumed_name]).join(".")
          enums << fq
        end
      end

      open_count = line.count("{")
      close_count = line.count("}")

      # If this line declared a new type/extension and opened a brace, push it
      # onto the context stack with the depth at which it was opened (i.e. the
      # depth before the brace was opened by this line).
      if consumed_kind && open_count > 0
        context_stack.push(name: consumed_name, opening_depth: brace_depth)
      end

      brace_depth += open_count - close_count

      while !context_stack.empty? && context_stack.last[:opening_depth] >= brace_depth
        context_stack.pop
      end
    end

    enums.uniq.sort
  end

  # Whether a declaration with the given SPI group should be considered
  # consumer-facing. `nil` means no SPI attribute (i.e. fully public).
  def consumer_facing_spi?(spi_group)
    spi_group.nil? || CONSUMER_FACING_SPI_GROUPS.include?(spi_group)
  end

  # Reads an allowlist file and returns the sorted set of fully-qualified enum
  # names contained in it (skipping blank lines and comments). Returns an
  # empty array if the file does not exist.
  def read_public_enums_allowlist(path)
    return [] unless File.exist?(path)

    File.foreach(path).filter_map do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")
      stripped
    end.uniq.sort
  end

  # Writes the allowlist file in canonical form: a header explaining what the
  # file is, then one fully-qualified enum name per line, sorted.
  def write_public_enums_allowlist(path, enums, scheme:)
    sorted = enums.uniq.sort
    header = <<~HEADER
      # Consumer-facing enums currently exposed by `#{scheme}`.
      #
      # This file enforces the company-wide policy that no NEW enum types may
      # be added to consumer-facing APIs (fully public + @_spi(Experimental)).
      # Existing enums are grandfathered in via this allowlist; new entries
      # require API council approval.
      #
      # `@_spi(Internal)` enums are intentionally excluded (they are not part
      # of the consumer-facing surface).
      #
      # To regenerate after an approved API change:
      #   bundle exec fastlane ios check_public_enums scheme:#{scheme} regenerate:true
      #
      # Format: one fully-qualified enum name per line (relative to the module),
      # e.g. `AppleReceipt.Environment`.
    HEADER

    body = sorted.map { |name| "#{name}\n" }.join
    File.write(path, header + "\n" + body)
  end

  def print_public_enums_failure_summary(scheme:, allowlist_path:, added:, removed:)
    Fastlane::UI.error("=" * 70)
    Fastlane::UI.error("PUBLIC-ENUMS POLICY VIOLATION (#{scheme})")
    Fastlane::UI.error("=" * 70)
    Fastlane::UI.error("")

    if added.any?
      Fastlane::UI.error("New consumer-facing enums detected (NOT in #{allowlist_path}):")
      added.each { |name| Fastlane::UI.error("  + #{name}") }
      Fastlane::UI.error("")
      Fastlane::UI.error("Per company policy, new public/Experimental enum types require")
      Fastlane::UI.error("API council approval. Use a struct with static constants or another")
      Fastlane::UI.error("non-enum type instead, unless you have explicit approval.")
      Fastlane::UI.error("")
    end

    if removed.any?
      Fastlane::UI.error("Stale entries in #{allowlist_path} (no longer present in the SDK):")
      removed.each { |name| Fastlane::UI.error("  - #{name}") }
      Fastlane::UI.error("")
      Fastlane::UI.error("Remove these stale entries from the allowlist, or restore the enum.")
      Fastlane::UI.error("")
    end

    Fastlane::UI.error("If this change has been approved, regenerate the allowlist:")
    Fastlane::UI.error("  bundle exec fastlane ios check_public_enums scheme:#{scheme} regenerate:true")
    Fastlane::UI.error("=" * 70)
  end
end
