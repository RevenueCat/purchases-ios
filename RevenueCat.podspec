Pod::Spec.new do |s|
  s.name             = "RevenueCat"
  s.version          = "4.25.10"
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
  s.swift_version       = '5.5'

  s.ios.deployment_target = '11.0'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'Sources/**/*.swift'
  s.exclude_files = 'Sources/LocalReceiptParsing/ReceiptParser-only-files/**'
  
  
end
