Pod::Spec.new do |s|
  s.name             = "RevenueCat_AdMob"
  s.version          = "5.62.0-SNAPSHOT"
  s.summary          = "AdMob adapter for RevenueCat ad tracking."

  s.description      = <<-DESC
                       RevenueCat_AdMob provides drop-in AdMob wrappers and extensions
                       that automatically report ad events to RevenueCat.
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.swift_version  = "5.8"

  s.ios.deployment_target = "15.0"

  # Required for CocoaPods to allow transitive dependency on Google-Mobile-Ads-SDK (statically linked).
  s.static_framework = true

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES"
  }

  s.source_files = "RevenueCat_AdMob/**/*.swift"
  s.exclude_files = [
    "RevenueCat_AdMob/Tests/**/*.swift",
    "RevenueCat_AdMob/**/Package*.swift"
  ]

  s.dependency "RevenueCat", s.version.to_s
  # Supports Google Mobile Ads SDK v12.x and v13.x.
  s.dependency "Google-Mobile-Ads-SDK", ">= 12.0", "< 14"
end
