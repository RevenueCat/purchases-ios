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

  def run_api_diff(api_diff_tool, old_file, new_file, platform_name)
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

    begin
      output = Fastlane::Actions.sh(
        api_diff_tool,
        "swift-interface",
        "--old",
        old_file,
        "--new",
        new_file
      )
      output = output.encode("UTF-8", invalid: :replace, undef: :replace)
      no_changes = output.include?("# ✅ No changes detected") || output.empty?

      if no_changes
        Fastlane::UI.success("✅ No breaking API changes for #{platform_name}")
      else
        Fastlane::UI.important("ℹ️ Non-breaking public API changes detected for #{platform_name}")
        result[:diff] = output
        puts output
      end
      result[:success] = true
    rescue => error
      Fastlane::UI.error("❌ Breaking API changes detected for #{platform_name}")
      result[:diff] = error.message.encode("UTF-8", invalid: :replace, undef: :replace)
    end

    result
  end

  def print_failure_summary(failed_platforms)
    Fastlane::UI.error("=" * 60)
    Fastlane::UI.error("BREAKING API CHANGES DETECTED")
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
    Fastlane::UI.error("If these breaking changes are intentional and approved, update the baseline files.")
    Fastlane::UI.error("Run: bundle exec fastlane ios update_swiftinterface_baselines")
    Fastlane::UI.error("Optional: add scheme:RevenueCat or scheme:RevenueCatUI")
    Fastlane::UI.error("=" * 60)
  end
end
