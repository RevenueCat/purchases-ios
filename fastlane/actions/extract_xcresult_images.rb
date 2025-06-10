module Fastlane
  module Actions
    class ExtractXcresultImagesAction < Action
      def self.run(params)
        require 'json'
        xcresult_path = params[:xcresult_path]
        output_dir = params[:output_dir]
        FileUtils.mkdir_p(output_dir)

        # Export all attachments
        command = [
          "xcrun", 
          "xcresulttool", 
          "export attachments",
          "--path '#{xcresult_path}'",
          "--test-id \"TakeScreenshotTests/testPaywallValidationScreenshots()\"",
          "--output-path #{output_dir}"
        ].join(" ")
        Actions.sh(command)

        command = [
          "xcrun",
          "xcresulttool",
          "get", 
          "test-results", 
          "activities", 
          "--path #{xcresult_path}",
          "--test-id \"TakeScreenshotTests/testPaywallValidationScreenshots()\""
        ].join(" ")
      
        # Fetch the root XCResult JSON
        json = Actions.sh(command)
        data = JSON.parse(json)

        uuid_map = {}

        data["testRuns"]&.each do |run|
          collect_attachments(run["activities"], uuid_map)
        end

        uuid_map.each do |uuid, name|
          Dir.glob("#{output_dir}/#{uuid}.*").each do |file|
            extension = File.extname(file)

            # Only keep the part of name before __END if it exists
            name = name.split("__END").first if name.include?("__END")

            File.rename(file, "#{output_dir}/#{name}#{extension}")
          end
        end

        FileUtils.rm_rf("#{output_dir}/manifest.json")
      end

      # Recursive method to collect all attachments from nested activities
      def self.collect_attachments(activities, uuid_map)
        activities&.each do |activity|
          if activity["attachments"]
            activity["attachments"].each do |attachment|
              uuid = attachment["uuid"]
              name = attachment["name"]
              uuid_map[uuid] = name if uuid && name
            end
          end

          # Recurse into childActivities
          if activity["childActivities"]
            collect_attachments(activity["childActivities"], uuid_map)
          end
        end
      end

      def self.description
        "Extracts images from an XCResult bundle and renames them based on their attachment names"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcresult_path,
                                      description: "Path to the XCResult bundle",
                                      type: String,
                                      optional: false),
          FastlaneCore::ConfigItem.new(key: :output_dir,
                                      description: "Directory where the images will be extracted",
                                      type: String,
                                      optional: false)
        ]
      end

      def self.authors
        ["RevenueCat"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end 