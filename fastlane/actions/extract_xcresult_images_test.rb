require "minitest/autorun"

module Fastlane
  module Actions
    class Action
    end
  end
end

require_relative "extract_xcresult_images"

class ExtractXcresultImagesActionTest < Minitest::Test
  def test_snapshot_file_name_does_not_duplicate_attachment_extension
    file_name = Fastlane::Actions::ExtractXcresultImagesAction.snapshot_file_name(
      attachment_name: "PaywallPreview.png",
      extension: ".png"
    )

    assert_equal "PaywallPreview.png", file_name
  end
end
