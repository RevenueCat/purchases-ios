#!/usr/bin/env ruby
# frozen_string_literal: true

# One-shot helper that wires the RulesEngine framework and its test bundle
# into the legacy RevenueCat.xcodeproj. The pbxproj is the source of truth
# for Carthage / xcframework export and for the Fastlane test_ios pipeline,
# so we wire those targets here in addition to the SPM and Tuist plumbing.
#
# Idempotent: re-running it is a no-op once the targets exist. Kept around
# under scripts/ so future agents can replay or extend it without spelunking
# the pbxproj by hand.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../RevenueCat.xcodeproj', __dir__)
RULES_ENGINE_SOURCES_DIR = 'RulesEngine'
RULES_ENGINE_TESTS_DIR = 'Tests/RulesEngineTests'
FRAMEWORK_TARGET_NAME = 'RulesEngine'
TEST_TARGET_NAME = 'RulesEngineTests'
FRAMEWORK_BUNDLE_ID = 'com.revenuecat.RulesEngine'
TESTS_BUNDLE_ID = 'com.revenuecat.RulesEngineTests'

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.native_targets.any? { |t| t.name == FRAMEWORK_TARGET_NAME }
  warn "#{FRAMEWORK_TARGET_NAME} already exists in the xcodeproj — nothing to do."
  exit 0
end

# --- Framework target ---------------------------------------------------------

framework_target = project.new_target(
  :framework,
  FRAMEWORK_TARGET_NAME,
  :ios,
  '13.0',
  nil,
  :swift,
)

# Shared deployment targets / supported platforms — mirror the other small
# frameworks (ReceiptParser / RevenueCatUI) to keep one consistent matrix.
shared_framework_settings = {
  'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
  'DEFINES_MODULE' => 'YES',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_NSHumanReadableCopyright' => 'Copyright © 2026 RevenueCat. All rights reserved.',
  'INSTALL_PATH' => '$(LOCAL_LIBRARY_DIR)/Frameworks',
  'IPHONEOS_DEPLOYMENT_TARGET' => '13.0',
  'MACOSX_DEPLOYMENT_TARGET' => '10.15',
  'TVOS_DEPLOYMENT_TARGET' => '13.0',
  'WATCHOS_DEPLOYMENT_TARGET' => '6.2',
  'XROS_DEPLOYMENT_TARGET' => '1.0',
  'PRODUCT_BUNDLE_IDENTIFIER' => FRAMEWORK_BUNDLE_ID,
  'PRODUCT_NAME' => '$(TARGET_NAME:c99extidentifier)',
  'PRODUCT_MODULE_NAME' => '$(TARGET_NAME:c99extidentifier)',
  'SDKROOT' => '',
  'SKIP_INSTALL' => 'NO',
  'SUPPORTED_PLATFORMS' => 'appletvos appletvsimulator iphoneos iphonesimulator macosx watchos watchsimulator xros xrsimulator',
  'SUPPORTS_MACCATALYST' => 'YES',
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'SWIFT_INSTALL_OBJC_HEADER' => 'NO',
  'SWIFT_STRICT_CONCURRENCY' => 'minimal',
  'SWIFT_VERSION' => '5.0',
  'TARGETED_DEVICE_FAMILY' => '1,2,3,4,7',
}

framework_target.build_configurations.each do |config|
  config.build_settings.merge!(shared_framework_settings)
  config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] =
    config.name == 'Debug' ? 'DEBUG $(inherited)' : '$(inherited)'
end

# Source file references — flat layout under RulesEngine/.
rules_engine_group = project.main_group.new_group(
  FRAMEWORK_TARGET_NAME,
  RULES_ENGINE_SOURCES_DIR,
)
Dir.glob(File.expand_path("../#{RULES_ENGINE_SOURCES_DIR}/**/*.swift", __dir__)).sort.each do |swift_file|
  relative = swift_file.sub("#{File.expand_path('..', __dir__)}/#{RULES_ENGINE_SOURCES_DIR}/", '')
  ref = rules_engine_group.new_reference(relative)
  framework_target.add_file_references([ref])
end

# --- Test target --------------------------------------------------------------

test_target = project.new_target(
  :unit_test_bundle,
  TEST_TARGET_NAME,
  :ios,
  '13.0',
  nil,
  :swift,
)

shared_test_settings = {
  'ALLOW_TARGET_PLATFORM_SPECIALIZATION' => 'YES',
  'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO',
  'CLANG_ENABLE_MODULES' => 'YES',
  'CLANG_ENABLE_OBJC_WEAK' => 'YES',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'PRODUCT_BUNDLE_IDENTIFIER' => TESTS_BUNDLE_ID,
  'PRODUCT_NAME' => '$(TARGET_NAME)',
  'SDKROOT' => '',
  'SKIP_INSTALL' => 'YES',
  'SUPPORTED_PLATFORMS' => 'appletvos appletvsimulator iphoneos iphonesimulator macosx watchos watchsimulator xros xrsimulator',
  'SUPPORTS_MACCATALYST' => 'YES',
  'SWIFT_VERSION' => '5.0',
  'TARGETED_DEVICE_FAMILY' => '1,2,3,4,6,7',
}

test_target.build_configurations.each do |config|
  config.build_settings.merge!(shared_test_settings)
  config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] =
    config.name == 'Debug' ? 'DEBUG' : ''
end

tests_group = project.main_group.new_group(
  TEST_TARGET_NAME,
  RULES_ENGINE_TESTS_DIR,
)
Dir.glob(File.expand_path("../#{RULES_ENGINE_TESTS_DIR}/**/*.swift", __dir__)).sort.each do |swift_file|
  relative = swift_file.sub("#{File.expand_path('..', __dir__)}/#{RULES_ENGINE_TESTS_DIR}/", '')
  ref = tests_group.new_reference(relative)
  test_target.add_file_references([ref])
end

test_target.add_dependency(framework_target)

# Ensure the test target links against the framework so `@testable import
# RulesEngine` resolves and we don't get duplicate symbol issues.
frameworks_phase = test_target.frameworks_build_phase
framework_product_ref = framework_target.product_reference
unless frameworks_phase.files.any? { |bf| bf.file_ref == framework_product_ref }
  frameworks_phase.add_file_reference(framework_product_ref)
end

project.save

puts "Added #{FRAMEWORK_TARGET_NAME} (uuid=#{framework_target.uuid}) and " \
     "#{TEST_TARGET_NAME} (uuid=#{test_target.uuid})."
