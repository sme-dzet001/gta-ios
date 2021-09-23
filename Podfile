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
end

target 'GTA' do
  shared_pods
end

target 'GTAStage' do
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
