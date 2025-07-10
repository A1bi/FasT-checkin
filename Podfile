platform :ios, '14.0'
use_frameworks!

target 'FasT-checkin' do
    pod 'MBProgressHUD', '~> 1.2.0'
    pod 'Sentry', '~> 8.53'
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
            end
        end
    end
end
