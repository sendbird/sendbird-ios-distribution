Pod::Spec.new do |s|
  s.name = 'SendbirdSplash'
  s.version = '1.0.1'
  s.summary = 'Sendbird customized Splash syntax highlighter'
  s.description = 'A fast, lightweight Swift syntax highlighter, customized for Delight AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdSplash-v#{s.version}"
  }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'Splash'
  s.source_files = 'Sources/Splash/Sources/Splash/**/*.swift'
  
  s.frameworks = 'Foundation'

  # SendbirdAIAgentCore 는 이 모듈을 library evolution 으로 빌드한 것에 맞춰 컴파일된다.
  # 같은 방식으로 빌드하지 않으면 앱이 실행 직후 protocol method descriptor 를 찾지 못하고 죽는다.
  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
