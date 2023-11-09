Pod::Spec.new do |s|
  s.name             = "PurchasesCoreSwift"
  s.version          = "3.14.4"
  s.summary          = "Swift portion of RevenueCat's Subscription and in-app-purchase backend service."

  s.description      = <<-DESC
                       Save yourself the hastle of implementing a subscriptions backend. Use RevenueCat instead https://www.revenuecat.com/
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.framework      = 'StoreKit'
  s.swift_version       = '5.0'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '9.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'PurchasesCoreSwift/**/*.{swift}'
  
end
