Pod::Spec.new do |s|
  s.name = 'SendbirdSplash'
  s.version = '1.0.0'
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

  # SendbirdMarkdownUI.podspec 의 같은 설정과 이유가 같다. Core 가 library evolution
  # 이 켜진 바이너리를 보고 컴파일되므로, 소스 pod 도 같게 빌드해야 심볼이 맞는다.
  #
  # 주의: 이 pod 이 쓰는 Sources/Splash 는 업스트림 0.16.0 의 포크다. 바이너리
  # Splash.xcframework 는 업스트림 원본으로 만든다. 지금은 SwiftGrammar.swift 한
  # 파일만 다르고 public API 가 같아서 ABI 가 맞지만, 포크의 public 선언을 건드리면
  # pod 고객이 실행 즉시 죽는다.
  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
