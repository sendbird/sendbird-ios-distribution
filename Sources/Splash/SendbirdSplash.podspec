Pod::Spec.new do |s|
  s.name = 'SendbirdSplash'
  s.version = '1.1.0'
  s.summary = 'Sendbird customized Splash syntax highlighter'
  s.description = 'A fast, lightweight Swift syntax highlighter, customized for Delight AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'Licenses/SendbirdSplash-NOTICE.txt' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }

  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdSplash-v#{s.version}"
  }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'Splash'

  # Xcode 27 의 iOS SDK 는 최소 배포 타깃이 15.0 이라 소스를 iOS 14 로 빌드하지
  # 못한다. 그러면 SendbirdAIAgentCore 의 ios14.0 swiftinterface 재컴파일이
  # 실패한다. 이 xcframework 의 swiftinterface 는 ios14.0 으로 고정돼 있다.
  #
  # 이 바이너리는 이 레포의 Sources/Splash 포크로 빌드한다. 업스트림과 달리
  # `any` 키워드 하이라이팅이 있고, 기존 CocoaPods 고객이 쓰던 코드와 같다.
  # SPM 이 받는 Splash.xcframework 는 업스트림 0.16.0 이라 서로 다른 자산이다.
  s.ios.vendored_frameworks = 'Splash.xcframework'

  s.frameworks = 'Foundation'

  # CocoaPods 는 prepare_command 앞에 set -e 를 이미 붙여 실행한다
  # (pod_source_preparer.rb). 아래 set -e 는 그 동작에 기대지 않으려는 중복이고,
  # test -d 는 unzip 이 0 을 반환했는데 디렉터리가 없는 경우를 막는다.
  s.prepare_command = <<-CMD
    set -e
    if [ ! -d "Splash.xcframework" ]; then
      curl -fsSL -o Splash-cocoapods.xcframework.zip "https://github.com/sendbird/sendbird-ios-distribution/releases/download/SendbirdSplash-v#{s.version}/Splash-cocoapods.xcframework.zip"
      unzip -oq Splash-cocoapods.xcframework.zip
      rm Splash-cocoapods.xcframework.zip
      test -d "Splash.xcframework"
    fi
  CMD
end
