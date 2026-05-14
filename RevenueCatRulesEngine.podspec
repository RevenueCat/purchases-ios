Pod::Spec.new do |s|
  s.name             = "RevenueCatRulesEngine"
  s.module_name      = "RulesEngine"
  s.version          = "5.74.0-SNAPSHOT"
  s.summary          = "Rules engine used internally by the RevenueCat SDK."

  s.description      = <<-DESC
                       Internal rules-evaluation library used by RevenueCat. Not intended for direct use by app developers.
                       DESC

  s.homepage         = "https://www.revenuecat.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "RevenueCat, Inc." => "support@revenuecat.com" }
  s.source           = { :git => "https://github.com/revenuecat/purchases-ios.git", :tag => s.version.to_s }
  s.documentation_url = "https://docs.revenuecat.com/"

  s.swift_version  = '5.8'

  s.ios.deployment_target = '13.0'
  s.watchos.deployment_target = '6.2'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.visionos.deployment_target = '1.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.source_files = 'RulesEngine/**/*.swift'
end
