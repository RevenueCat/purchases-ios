source "https://rubygems.org"

# Temporarily pointing to a pre-release of fastlane to test out xcbeautify and integration of trainer
# gem 'fastlane'
gem 'fastlane', git: 'https://github.com/fastlane/fastlane.git', branch: 'remove-xcpretty-dependency-add-xcbeautify-option'

gem 'cocoapods'
gem 'jazzy'
gem 'cocoapods-trunk'
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
