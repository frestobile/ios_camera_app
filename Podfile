# Uncomment the next line to define a global platform for your project

target 'VIService' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VIService

  pod 'SkyFloatingLabelTextField'
  pod 'iOS-Camera-Button'
  pod 'Alamofire', '~> 4.6'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'TPKeyboardAvoidingSwift'
  pod 'SwiftyCam'
  pod 'mobile-ffmpeg-full', '~> 4.4'
  # pod 'ffmpeg-kit-ios-full', '~> 6.0'

  target 'VIServiceTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'VIServiceUITests' do
    # Pods for testing
  end
end
post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end

