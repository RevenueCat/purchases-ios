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
    app_group: storekit_app_group,
    octane_path: octane_path,
    storekit_dir: storekit_dir,
    storekit_file: storekit_file
  }
end

def setup_storekit_config(bundle_id, source_config, paths)
  begin
    # Create directory structure if needed
    FileUtils.mkdir_p(paths[:storekit_dir]) unless File.directory?(paths[:storekit_dir])

    # Copy config if it doesn't exist
    unless File.exist?(paths[:storekit_file])
      FileUtils.cp(source_config, paths[:storekit_file])
      puts "[#{Time.now}] ✅ Recreated StoreKit config at: #{paths[:storekit_file]}"
      return true
    end
  rescue => e
    puts "[#{Time.now}] ❌ Error setting up StoreKit config: #{e.message}"
    return false
  end
  false
end

puts "🔍 Starting StoreKit config file watcher..."
puts "   Bundle ID: #{bundle_id}"
puts "   Source config: #{storekit_config_source}"

# Get initial paths
paths = get_storekit_paths(bundle_id)
unless paths
  puts "❌ Could not determine StoreKit paths"
  exit 1
end

puts "   Watching: #{paths[:storekit_file]}"
puts ""

# Track what exists
last_check = {
  app_group: File.exist?(paths[:app_group]),
  octane_path: File.exist?(paths[:octane_path]),
  storekit_dir: File.exist?(paths[:storekit_dir]),
  storekit_file: File.exist?(paths[:storekit_file])
}

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

# Watch loop
loop do
  break if shutdown

  begin
    # Check if paths still exist
    current_check = {
      app_group: File.exist?(paths[:app_group]),
      octane_path: File.exist?(paths[:octane_path]),
      storekit_dir: File.exist?(paths[:storekit_dir]),
      storekit_file: File.exist?(paths[:storekit_file])
    }

    # Detect deletions
    if current_check != last_check
      puts "[#{Time.now}] 🔄 Change detected:"

      [:app_group, :octane_path, :storekit_dir, :storekit_file].each do |key|
        if last_check[key] && !current_check[key]
          puts "   - #{key} was deleted"
        end
      end

      # If any part of the path was deleted, recreate the config
      if current_check.values.any? { |exists| !exists }
        puts "[#{Time.now}] 🔧 Recreating StoreKit configuration..."
        setup_storekit_config(bundle_id, storekit_config_source, paths)
      end

      last_check = current_check
    end

  rescue => e
    puts "[#{Time.now}] ⚠️  Error in watch loop: #{e.message}"
  end

  sleep 0.5
end

puts "👋 StoreKit config watcher stopped"
