Pod::Spec.new do |s|
  s.name             = "Purchases"
  s.version          = "3.1.2"
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

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = [
    'Purchases/Public/Purchases.h',
    'Purchases/*.h',
    'Purchases/*.m',
    'Purchases/Public/*.h',
    'Purchases/Public/*.m',
    'Purchases/Caching/*.h',
    'Purchases/Caching/*.m',
    'Purchases/SubscriberAttributes/*.h',
    'Purchases/SubscriberAttributes/*.m',
  ]


  s.public_header_files = [
    'Purchases/Public/Purchases.h',
    "Purchases/Public/*.h"
  ]

end
