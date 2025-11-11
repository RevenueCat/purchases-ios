#!/usr/bin/env ruby

require 'fileutils'

# Get arguments
bundle_id = ARGV[0]
storekit_config_source = ARGV[1]

unless bundle_id && storekit_config_source
  puts "Usage: ruby storekit_config_file_watcher.rb <bundle_id> <storekit_config_path>"
  exit 1
end

unless File.exist?(storekit_config_source)
  puts "Error: StoreKit config not found at #{storekit_config_source}"
  exit 1
end

def get_storekit_paths(bundle_id)
  # Get the app container path
  container_path = `xcrun simctl get_app_container booted "#{bundle_id}"`.strip
  return nil unless $?.success?

  # Extract base container path
  match = container_path.match(/(.*\/data\/Containers)/)
  return nil unless match
  base_container_path = match[1]

  # Find the StoreKit app group container
  app_group_pattern = "#{base_container_path}/Shared/AppGroup/*"
  app_group_dirs = Dir.glob(app_group_pattern)

  storekit_app_group = app_group_dirs.find do |app_group_dir|
    metadata_plist = File.join(app_group_dir, '.com.apple.mobile_container_manager.metadata.plist')
    next false unless File.exist?(metadata_plist)

    begin
      identifier = `plutil -extract MCMMetadataIdentifier raw -o - "#{metadata_plist}"`.strip
      identifier == 'group.com.apple.storekit'
    rescue
      false
    end
  end

  return nil unless storekit_app_group

  octane_path = File.join(storekit_app_group, 'Documents', 'Persistence', 'Octane')
  storekit_dir = File.join(octane_path, bundle_id, 'Configuration.storekit')
  storekit_file = File.join(storekit_dir, 'Configuration.storekit')

  {
    storekit_dir: storekit_dir,
    storekit_file: storekit_file
  }
end

def setup_storekit_config(bundle_id, source_config)
  paths = get_storekit_paths(bundle_id)
  return false unless paths

  # Check if config already exists
  return true if File.exist?(paths[:storekit_file])

  # Create directory structure if needed
  FileUtils.mkdir_p(paths[:storekit_dir]) unless File.directory?(paths[:storekit_dir])

  # Copy config file
  FileUtils.cp(source_config, paths[:storekit_file])

  if File.exist?(paths[:storekit_file])
    puts "[#{Time.now}] ✅ Recreated StoreKit config at: #{paths[:storekit_file]}"
    true
  else
    puts "[#{Time.now}] ❌ Failed to create StoreKit config"
    false
  end
end

puts "🔍 Starting StoreKit config file watcher..."
puts "   Bundle ID: #{bundle_id}"
puts "   Source config: #{storekit_config_source}"
puts "   Checking every 0.5 seconds..."
puts ""

# Handle shutdown gracefully
shutdown = false
trap('TERM') do
  puts "\n🛑 Received shutdown signal"
  shutdown = true
end
trap('INT') do
  puts "\n🛑 Received interrupt signal"
  shutdown = true
end

# Watch loop - just call setup repeatedly
# It will early return if the file already exists
loop do
  break if shutdown

  begin
    setup_storekit_config(bundle_id, storekit_config_source)
  rescue => e
    puts "[#{Time.now}] ⚠️  Error: #{e.message}"
  end

  sleep 0.5
end

puts "👋 StoreKit config watcher stopped"
