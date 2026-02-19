Pod::Spec.new do |s|
  s.name             = "RevenueCat"
  s.version          = "5.60.0-SNAPSHOT"
  s.summary          = "Subscription and in-app-purchase backend service."

  s.description      = <<-DESC
                       Save yourself the hassle of implementing a subscriptions backend. Use RevenueCat instead https://www.revenuecat.com/
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.framework      = 'StoreKit'
  s.swift_version  = '5.8'

  s.ios.deployment_target = '13.0'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.visionos.deployment_target = '1.0'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=xros*]' => '$(inherited) VISION_OS',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=xrsimulator*]' => '$(inherited) VISION_OS',
  }

  s.source_files = 'Sources/**/*.swift'
  s.exclude_files = 'Sources/LocalReceiptParsing/ReceiptParser-only-files/**'
  
  s.resource_bundles = {'RevenueCat' => ['Sources/PrivacyInfo.xcprivacy']}
end
