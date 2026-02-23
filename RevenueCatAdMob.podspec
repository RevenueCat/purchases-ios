Pod::Spec.new do |s|
  s.name             = "RevenueCatAdMob"
  s.version          = "5.60.0-SNAPSHOT"
  s.summary          = "AdMob adapter for RevenueCat ad tracking."

  s.description      = <<-DESC
                       RevenueCatAdMob provides drop-in AdMob wrappers and extensions
                       that automatically report ad events to RevenueCat.
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.swift_version  = "5.7"

  s.ios.deployment_target = "15.0"

  # Required for CocoaPods to allow transitive dependency on Google-Mobile-Ads-SDK (statically linked).
  s.static_framework = true

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES"
  }

  s.source_files = "RevenueCatAdMob/**/*.swift"
  s.exclude_files = [
    "RevenueCatAdMob/Tests/**/*.swift",
    "RevenueCatAdMob/Support/**/*",
    "RevenueCatAdMob/**/Package*.swift"
  ]

  s.dependency "RevenueCat", s.version.to_s
  # Supports Google Mobile Ads SDK v11.x, v12.x, and v13.x.
  s.dependency "Google-Mobile-Ads-SDK", ">= 11.2", "< 14"
end
