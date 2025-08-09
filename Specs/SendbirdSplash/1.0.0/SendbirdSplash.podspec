Pod::Spec.new do |s|
  s.name = 'SendbirdSplash'
  s.version = '1.0.0'
  s.summary = 'Sendbird customized Splash syntax highlighter'
  s.description = 'A fast, lightweight Swift syntax highlighter, customized for Sendbird AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "SendbirdSplash-v#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  s.module_name = 'Splash'
  s.source_files = 'Sources/Splash/Sources/Splash/**/*.swift'
  
  s.frameworks = 'Foundation'
end
