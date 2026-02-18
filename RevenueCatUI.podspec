Pod::Spec.new do |s|
  s.name             = "RevenueCatUI"
  s.version          = "5.60.0-SNAPSHOT"
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
  s.swift_version  = '5.8'

  # RevenueCatUI APIs are not available in all these platforms / versions, however retaining this support at the Pod level 
  # allows us to depend on it in the same platforms as RevenueCat.
  # Opening support allows us to depend on it in the same platforms as RevenueCat.
  s.ios.deployment_target = '13.0'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.visionos.deployment_target = '1.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'RevenueCatUI/**/*.swift'

  s.dependency 'RevenueCat', s.version.to_s

  s.resource_bundles = {
    'RevenueCat_RevenueCatUI' => [
      # This is done automatically by SPM but must be added manually here:
      'RevenueCatUI/Resources/*.lproj/*.strings',
       # Note: these have to match the values in Package.swift
       'RevenueCatUI/Resources/background.jpg',
       'RevenueCatUI/Resources/icons.xcassets',
    ]
  }
  
end
