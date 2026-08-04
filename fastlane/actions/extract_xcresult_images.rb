module Fastlane
  module Actions
    class ExtractXcresultImagesAction < Action
      def self.run(params)
        require 'fileutils'
        require 'json'

        xcresult_path = params[:xcresult_path]
        output_dir = params[:output_dir]
        test_id = params[:test_id]
        include_test_identifier = params[:include_test_identifier]
        export_dir = File.join(output_dir, ".xcresult-attachments")

        FileUtils.mkdir_p(output_dir)
        FileUtils.rm_rf(export_dir)

        export_command = [
          "xcrun",
          "xcresulttool",
          "export",
          "attachments",
          "--path",
          xcresult_path,
          "--output-path",
          export_dir
        ]
        export_command.push("--test-id", test_id) if test_id
        Actions.sh(*export_command)

        manifest_path = File.join(export_dir, "manifest.json")
        UI.user_error!("xcresulttool did not produce #{manifest_path}") unless File.exist?(manifest_path)

        original_names_by_uuid = test_id ? original_attachment_names(xcresult_path, test_id) : {}
        manifest = JSON.parse(File.read(manifest_path))
        test_attachments = collect_test_attachments(manifest)
        exported_images = 0

        test_attachments.each do |test_attachment|
          test_identifier = test_attachment["testIdentifier"]
          if include_test_identifier && !test_identifier
            UI.user_error!("XCResult attachment group is missing its test identifier")
          end

          Array(test_attachment["attachments"]).each do |attachment|
            exported_file_name = attachment["exportedFileName"]
            suggested_name = attachment["suggestedHumanReadableName"]
            next unless exported_file_name && suggested_name

            source = File.join(export_dir, exported_file_name)
            extension = File.extname(source)
            next unless File.file?(source) && image_extension?(extension)

            uuid = File.basename(exported_file_name, extension)
            attachment_name = original_names_by_uuid[uuid] || stable_attachment_name(suggested_name, extension)
            destination_name = snapshot_file_name(
              attachment_name: attachment_name,
              extension: extension,
              test_identifier: include_test_identifier ? test_identifier : nil
            )
            destination = File.join(output_dir, destination_name)
            UI.user_error!("Multiple XCResult images have the name '#{destination_name}'") if File.exist?(destination)

            FileUtils.mv(source, destination)
            exported_images += 1
          end
        end

        FileUtils.rm_rf(export_dir)
        UI.user_error!("No image attachments found in #{xcresult_path}") if exported_images.zero?

        UI.message("Extracted #{exported_images} image attachments from #{xcresult_path}")
      end

      def self.original_attachment_names(xcresult_path, test_id)
        activities = Actions.sh(
          "xcrun",
          "xcresulttool",
          "get",
          "test-results",
          "activities",
          "--path",
          xcresult_path,
          "--test-id",
          test_id
        )
        data = JSON.parse(activities)
        names_by_uuid = {}

        data["testRuns"]&.each do |run|
          collect_activity_attachment_names(run["activities"], names_by_uuid)
        end

        names_by_uuid
      end

      def self.collect_activity_attachment_names(activities, names_by_uuid)
        activities&.each do |activity|
          Array(activity["attachments"]).each do |attachment|
            uuid = attachment["uuid"]
            name = attachment["name"]
            names_by_uuid[uuid] = name if uuid && name
          end

          collect_activity_attachment_names(activity["childActivities"], names_by_uuid)
        end
      end

      def self.collect_test_attachments(value, test_attachments = [])
        case value
        when Hash
          if value.key?("testIdentifier") && value.key?("attachments")
            test_attachments << value
          else
            value.each_value { |child| collect_test_attachments(child, test_attachments) }
          end
        when Array
          value.each { |child| collect_test_attachments(child, test_attachments) }
        end

        test_attachments
      end

      def self.stable_attachment_name(suggested_name, extension)
        name = suggested_name.sub(/#{Regexp.escape(extension)}\z/i, "")
        name = name.sub(/_\d+_[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i, "")
        name.sub(/#{Regexp.escape(extension)}\z/i, "")
      end

      def self.snapshot_file_name(attachment_name:, extension:, test_identifier: nil)
        # Existing screenshot tests use __END to delimit the filename from attachment metadata.
        attachment_name = attachment_name.split("__END").first

        if test_identifier
          # SnapshotPreviews adds a global test index which changes whenever an earlier Preview is inserted.
          stable_test_identifier = test_identifier.sub(/-\d+\(\)\z/, "")
          attachment_name = "#{stable_test_identifier}__#{attachment_name}"
        end

        sanitized_name = attachment_name
                         .gsub(/[\\\/]/, "__")
                         .gsub(/[^0-9A-Za-z._() -]/, "_")
                         .gsub(/\s+/, " ")
                         .strip
        UI.user_error!("XCResult image attachment has an invalid name: #{attachment_name.inspect}") if sanitized_name.empty?

        "#{sanitized_name}#{extension.downcase}"
      end

      def self.image_extension?(extension)
        [".png", ".jpg", ".jpeg"].include?(extension.downcase)
      end

      def self.description
        "Extracts named image attachments from an XCResult bundle"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcresult_path,
                                      description: "Path to the XCResult bundle",
                                      type: String,
                                      optional: false),
          FastlaneCore::ConfigItem.new(key: :output_dir,
                                      description: "Directory where the image attachments will be extracted",
                                      type: String,
                                      optional: false),
          FastlaneCore::ConfigItem.new(key: :test_id,
                                      description: "Optional XCTest identifier whose attachments should be extracted",
                                      type: String,
                                      optional: true),
          FastlaneCore::ConfigItem.new(key: :include_test_identifier,
                                      description: "Prefix filenames with their XCTest identifier to avoid collisions",
                                      is_string: false,
                                      default_value: false)
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
