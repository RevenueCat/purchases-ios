# Helper module for API diff functionality
# Used by generate_swiftinterface and check_api_changes lanes

module ApiDiffHelper
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
  ].freeze

  PLATFORM_CHECKS = [
    { suffix: "-ios-simulator", name: "iOS Simulator" },
    { suffix: "-ios", name: "iOS" },
    { suffix: "-macos", name: "macOS" },
    { suffix: "-watchos-simulator", name: "watchOS Simulator" },
    { suffix: "-watchos", name: "watchOS" },
    { suffix: "-tvos-simulator", name: "tvOS Simulator" },
    { suffix: "-tvos", name: "tvOS" }
  ].freeze

  PR_SWIFTINTERFACE_DIR = "/tmp/pr-swiftinterface".freeze
  API_DIFFS_DIR = "/tmp/api-diffs".freeze

  module_function

  def swiftinterface_pattern_for_sdk(sdk)
    case sdk
    when "iphonesimulator"
      "**/Release-iphonesimulator/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "iphoneos"
      "**/Release-iphoneos/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "macosx"
      "**/Release/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "watchsimulator"
      "**/Release-watchsimulator/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "watchos"
      "**/Release-watchos/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "appletvsimulator"
      "**/Release-appletvsimulator/**/Objects-normal/**/RevenueCat.swiftinterface"
    when "appletvos"
      "**/Release-appletvos/**/Objects-normal/**/RevenueCat.swiftinterface"
    else
      "**/RevenueCat.swiftinterface"
    end
  end

  def find_swiftinterface_file(derived_data_dir, sdk)
    pattern = swiftinterface_pattern_for_sdk(sdk)
    Dir.glob("#{derived_data_dir}/#{pattern}")
       .reject { |path| path.include?("private") }
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
      output = Fastlane::Actions.sh(api_diff_tool, "swift-interface", "--old", old_file, "--new", new_file)
      no_changes = output.include?("# ✅ No changes detected") || output.empty?

      if no_changes
        Fastlane::UI.success("✅ No API changes for #{platform_name}")
        result[:success] = true
      else
        Fastlane::UI.error("❌ API changes detected for #{platform_name}")
        result[:diff] = output
      end
    rescue => e
      Fastlane::UI.error("❌ Breaking API changes detected for #{platform_name}")
      begin
        result[:diff] = Fastlane::Actions.sh(
          api_diff_tool, "swift-interface", "--old", old_file, "--new", new_file,
          error_callback: ->(r) { r }
        )
      rescue => diff_e
        result[:diff] = diff_e.message
      end
      result[:diff] = result[:diff].encode('UTF-8', invalid: :replace, undef: :replace) if result[:diff]
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
    Fastlane::UI.error("Run: bundle exec fastlane ios generate_swiftinterface")
    Fastlane::UI.error("Then copy files from /tmp/pr-swiftinterface/ to the repo root.")
    Fastlane::UI.error("=" * 60)
  end
end
