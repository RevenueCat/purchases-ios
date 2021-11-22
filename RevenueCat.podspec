Pod::Spec.new do |s|
  s.name             = "RevenueCat"
  s.version          = "4.0.0-beta.7"
  s.summary          = "Subscription and in-app-purchase backend service."

  s.description      = <<-DESC
                       Save yourself the hastle of implementing a subscriptions backend. Use RevenueCat instead https://www.revenuecat.com/
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.framework      = 'StoreKit'
  s.swift_version       = '5.5'

  # todo: deployment_target set to 12.0 instead of 9.0 temporarily for iOS due to a known issue in 
  # Xcode-beta 5, where swift libraries fail to build for iOS targets that use armv7.
  # See issue 74120874 in the release notes:
  # https://developer.apple.com/documentation/xcode-release-notes/xcode-13-beta-release-notes
  s.ios.deployment_target = '12.0'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'Purchases/**/*.swift'
  
  
end
