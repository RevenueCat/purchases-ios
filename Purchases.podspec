Pod::Spec.new do |s|
  s.name             = "Purchases"
  s.version          = "1.2.0-rc2"
  s.summary          = "Subscription and in-app-purchase backend service."

  s.description      = <<-DESC
                       Save yourself the hastle of implementing a subscriptions backend. Use RevenueCat instead http://revenue.cat
                       DESC

  s.homepage         = "http://revenue.cat"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "jacob@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.framework      = 'StoreKit'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'

  s.source_files = [
    'Purchases/Public/Purchases.h',
    'Purchases/*.h',
    'Purchases/*.m',
    'Purchases/Public/*.h',
    'Purchases/Public/*.m',
  ]


  s.public_header_files = [
    'Purchases/Public/Purchases.h',
    "Purchases/Public/*.h"
  ]

end
