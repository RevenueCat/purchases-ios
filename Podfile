# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Purchases' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Purchases

  target 'PurchasesTests' do
    pod 'Nimble', '~> 9.0.0-rc.3'
    pod 'OHHTTPStubs/Swift'
  end

end

target 'PurchasesCoreSwift' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for PurchasesCoreSwift

  target 'PurchasesCoreSwiftTests' do
    pod 'Nimble', '~> 9.0.0-rc.3'
    pod 'OHHTTPStubs/Swift'
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
