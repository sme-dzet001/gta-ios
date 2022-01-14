# Uncomment the next line to define a global platform for your project
# platform :ios, '13.0'

  use_frameworks!

# Pods for GTA

def shared_pods
  pod 'RNCryptor'
  pod 'PanModal'
  pod 'AdvancedPageControl'
  pod 'Firebase/Crashlytics'
  pod 'Kingfisher'
  pod 'SDWebImage'
  pod 'Charts'
  pod 'Parchment'
  pod 'Hero' 
end

target 'GTA' do
  shared_pods
end

target 'GTAUat' do
  shared_pods
end

target 'GTADev' do
  shared_pods
end

target 'QA-GTAStage' do
  shared_pods
end

target 'GTATests' do
  inherit! :search_paths
   # Pods for testing
 end

target 'GTAUITests' do
   # Pods for testing
end

#Avoid Xcode warnings about deployment target in pod projects
post_install do |postinstaller|
  postinstaller.pods_project.targets.each do |target|
    target.build_configurations.each do |buildconfig|
      if buildconfig.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] < '13.0'
        buildconfig.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
