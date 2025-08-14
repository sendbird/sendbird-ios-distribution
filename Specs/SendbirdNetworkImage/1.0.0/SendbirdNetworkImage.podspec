Pod::Spec.new do |s|
  s.name = 'SendbirdNetworkImage'
  s.version = '1.0.0'
  s.summary = 'Sendbird customized NetworkImage for SwiftUI'
  s.description = 'AsyncImage before iOS 15, with cache and support for custom placeholders, customized for Sendbird'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdNetworkImage-v#{s.version}"
  }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'SendbirdNetworkImage'
  s.source_files = 'Sources/NetworkImage/Sources/**/*.swift'
  
  s.frameworks = 'SwiftUI', 'Combine'
end
