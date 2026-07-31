module Fastlane
  module Actions
    class ExtractXcresultAttachmentsAction < Action
      def self.run(params)
        require 'fileutils'
        require 'json'

        xcresult_path = params[:xcresult_path]
        output_dir = params[:output_dir]
        export_dir = File.join(output_dir, ".xcresult-attachments")

        FileUtils.mkdir_p(output_dir)
        FileUtils.rm_rf(export_dir)

        Actions.sh(
          "xcrun",
          "xcresulttool",
          "export",
          "attachments",
          "--path",
          xcresult_path,
          "--output-path",
          export_dir
        )

        manifest_path = File.join(export_dir, "manifest.json")
        UI.user_error!("xcresulttool did not produce #{manifest_path}") unless File.exist?(manifest_path)

        manifest = JSON.parse(File.read(manifest_path))
        attachments = collect_attachments(manifest)
        exported_images = 0

        attachments.each do |attachment|
          exported_file_name = attachment["exportedFileName"]
          suggested_name = attachment["suggestedHumanReadableName"]
          next unless exported_file_name && suggested_name

          source = File.join(export_dir, exported_file_name)
          next unless File.file?(source) && File.extname(source).casecmp?(".png")

          destination_name = snapshot_file_name(suggested_name)
          destination = File.join(output_dir, destination_name)
          UI.user_error!("Multiple Preview snapshots have the name '#{destination_name}'") if File.exist?(destination)

          FileUtils.mv(source, destination)
          exported_images += 1
        end

        FileUtils.rm_rf(export_dir)
        UI.user_error!("No PNG attachments found in #{xcresult_path}") if exported_images.zero?

        UI.message("Extracted #{exported_images} PNG attachments from #{xcresult_path}")
      end

      def self.collect_attachments(value, attachments = [])
        case value
        when Hash
          if value.key?("exportedFileName") && value.key?("suggestedHumanReadableName")
            attachments << value
          else
            value.each_value { |child| collect_attachments(child, attachments) }
          end
        when Array
          value.each { |child| collect_attachments(child, attachments) }
        end

        attachments
      end

      def self.snapshot_file_name(suggested_name)
        base_name = suggested_name.sub(/\.png\z/i, "")
        sanitized_name = base_name
                         .gsub(/[\\\/]/, "__")
                         .gsub(/[^0-9A-Za-z._() -]/, "_")
                         .gsub(/\s+/, " ")
                         .strip

        UI.user_error!("Preview snapshot attachment has an invalid name: #{suggested_name.inspect}") if sanitized_name.empty?
        "#{sanitized_name}.png"
      end

      def self.description
        "Extracts named PNG attachments from an XCResult bundle"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcresult_path,
                                      description: "Path to the XCResult bundle",
                                      type: String,
                                      optional: false),
          FastlaneCore::ConfigItem.new(key: :output_dir,
                                      description: "Directory where the PNG attachments will be extracted",
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
