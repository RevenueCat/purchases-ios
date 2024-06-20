require 'nokogiri'

module Fastlane
  module Actions
    module SharedValues
      RETRY_SCAN_SAVE_FAILED_TESTS_CUSTOM_VALUE = :RETRY_SCAN_SAVE_FAILED_TESTS_CUSTOM_VALUE
    end

    class RetryScanSaveFailedTestsAction < Action
      def self.run(params)
        # './test_output/xctest/ios/report.junit'
        report_path = params[:junit_report_path]
        report_path = File.absolute_path(report_path)

        # original
        copy_path = params[:copy_path]
        FileUtils.cp(report_path, copy_path)

        save_failed_tests(report_path)

        merge_path = params[:merge_path]
        if merge_path
          merge_and_replace_junit(report_path, merge_path)
        end
      end

      def self.merge_and_replace_junit(retry_report_path, original_report)
        merged_report = merge_reports(original_report, retry_report_path)
        save_report(merged_report, original_report)
    
        FileUtils.rm_rf('./test_output/xctest/ios/retry')
    
        UI.message "Merged report saved to #{original_report}"
      end

      def self.parse_report(file_path)
        Nokogiri::XML(File.open(file_path))
      end
      
      def self.merge_reports(original_report, retry_report)
        original_doc = parse_report(original_report)
        retry_doc = parse_report(retry_report)
      
        original_testcases = original_doc.xpath('//testcase')
        retry_testcases = retry_doc.xpath('//testcase')
      
        retry_count = 0
      
        retry_testcases.each do |retry_testcase|
          suitename = retry_testcase.parent['name'] # Retrieve suitename
          classname = retry_testcase['classname']
          name = retry_testcase['name']
      
          original_testcase = original_testcases.find do |tc|
            tc['classname'] == classname && tc['name'] == name && tc.parent['name'] == suitename
          end
      
          if original_testcase
            original_testcase.at('failure')&.remove # Remove failure from original
      
            # Add retry count attribute to the testcase
            current_retry_count = original_testcase['retry_count'].to_i
            original_testcase['retry_count'] = (current_retry_count + 1).to_s
      
            retry_count += 1
          end
        end
      
        # Add total retry count as a property in the testsuite
        properties_node = original_doc.at('testsuite > properties') || Nokogiri::XML::Node.new('properties', original_doc.at('testsuite'))
        original_doc.at('testsuite').add_child(properties_node) unless original_doc.at('testsuite > properties')
      
        retry_property = Nokogiri::XML::Node.new('property', original_doc)
        retry_property['name'] = 'total_retries'
        retry_property['value'] = retry_count.to_s
      
        properties_node.add_child(retry_property)
      
        original_doc
      end
      
      def self.save_report(doc, output_path)
        File.open(output_path, 'w') { |file| file.write(doc.to_xml) }
      end

      def self.failed_tests_path
        File.absolute_path('./fastlane/test_output/xctest/ios/failed_tests.txt')
      end

      def self.save_failed_tests(report_path)
        failed_tests = []
        
        if File.exist?(report_path)
          doc = Nokogiri::XML(File.open(report_path))
      
          doc.xpath('//testcase[failure]').each do |test_case|
            suitename = test_case.parent['name'] # Retrieve the suitename
            classname = test_case['classname']
            name = test_case['name']
            failed_tests << "#{suitename}/#{classname}/#{name}"
          end
    
          failed_tests = failed_tests.uniq
      
          File.open(failed_tests_path, 'w') do |file|
            file.puts(failed_tests)
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'A short description with <= 80 characters of what this action does'
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        'You can use this action to do cool things...'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :junit_report_path,
                                       description: 'Path of the junit report',
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :copy_path,
                                       description: 'Path of copy the junit report too',
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :merge_path,
                                       description: 'Path to merge the junit report into',
                                       optional: true)
        ]
      end

      def self.output
        []
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['joshdholtz']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
