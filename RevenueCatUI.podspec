Pod::Spec.new do |s|
  s.name             = "RevenueCatUI"
  s.version          = "4.31.0-SNAPSHOT"
  s.summary          = "UI library for RevenueCat paywalls."

  s.description      = <<-DESC
                       Save yourself the hassle of implementing a subscriptions backend. Use RevenueCat instead https://www.revenuecat.com/
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.framework      = 'SwiftUI'
  s.swift_version  = '5.7'

  # Technically PaywallView isn't available until iOS 15,
  # but this can be detected at compile time.
  s.ios.deployment_target = '11.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'RevenueCatUI/**/*.swift'

  s.dependency 'RevenueCat', s.version.to_s

  s.resource_bundles = {
    'RevenueCat_RevenueCatUI' => [
       # Note: these have to match the values in Package.swift
       'RevenueCatUI/Resources/background.jpg',
       'RevenueCatUI/Resources/icons.xcassets',
    ]
  }
  
end
