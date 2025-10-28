module Fastlane
  module Actions
    class SetupSimulatorStorekitConfigAction < Action
      def self.run(params)
        bundle_id = params[:bundle_id]
        storekit_config_path = params[:storekit_config_path]

        # Verify StoreKit config exists
        unless File.exist?(storekit_config_path)
          UI.user_error!("StoreKit configuration not found at: #{storekit_config_path}")
        end

        UI.message("Setting up StoreKit configuration for app: #{bundle_id}")

        # Get the app container path
        container_path = Actions.sh("xcrun", "simctl", "get_app_container", "booted", bundle_id, log: false).strip
        UI.message("App container path: #{container_path}")

        # Extract the base path up to and including "data/Containers"
        unless container_path =~ /(.*\/data\/Containers)\//
          UI.user_error!("Could not extract base path from: #{container_path}")
        end

        base_container_path = $1
        UI.message("Base container path: #{base_container_path}")

        # Find the Octane folder
        octane_pattern = "#{base_container_path}/Shared/AppGroup/*/Documents/Persistence/Octane"
        UI.message("Searching for Octane folder: #{octane_pattern}")

        octane_path = Dir.glob(octane_pattern).first

        if octane_path.nil?
          UI.user_error!("Could not find Octane folder. Pattern: #{octane_pattern}")
        end

        UI.success("Found Octane path: #{octane_path}")

        # Construct the destination paths
        storekit_dir = File.join(octane_path, bundle_id, "Configuration.storekit")
        storekit_file = File.join(storekit_dir, "Configuration.storekit")

        UI.message("Creating directory: #{storekit_dir}")
        Actions.sh("mkdir", "-p", storekit_dir, log: false)

        UI.message("Copying StoreKit configuration...")
        Actions.sh("cp", storekit_config_path, storekit_file, log: false)

        # Verify
        unless File.exist?(storekit_file)
          UI.user_error!("Failed to copy StoreKit configuration")
        end

        UI.success("✅ StoreKit configuration installed at:")
        UI.message("   #{storekit_file}")

        storekit_file
      end

      def self.description
        "Installs a StoreKit configuration file in the correct location for a simulator app to use during testing"
      end

      def self.details
        "This action copies a StoreKit configuration file to the Octane directory structure " \
        "within the iOS simulator, allowing the app to use local StoreKit testing without " \
        "connecting to the App Store. The configuration file must be placed at: " \
        "data/Containers/Shared/AppGroup/{UUID}/Documents/Persistence/Octane/{bundle_id}/Configuration.storekit/Configuration.storekit"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :bundle_id,
            description: "The bundle identifier of the app installed in the simulator",
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :storekit_config_path,
            description: "Path to the StoreKit configuration file (.storekit)",
            type: String,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("StoreKit config file not found at '#{value}'") unless File.exist?(value)
              UI.user_error!("File must be a .storekit file") unless value.end_with?('.storekit')
            end
          )
        ]
      end

      def self.return_value
        "The full path to the installed StoreKit configuration file"
      end

      def self.authors
        ["rickvdl"]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.example_code
        [
          'setup_simulator_storekit_config(
            bundle_id: "com.example.myapp",
            storekit_config_path: "path/to/StoreKitConfiguration.storekit"
          )'
        ]
      end

      def self.category
        :testing
      end
    end
  end
end
