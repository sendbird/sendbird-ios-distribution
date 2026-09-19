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

  # set -e 와 test 가 없으면, 프록시가 200 으로 HTML 을 주는 경우 unzip 이 실패해도
  # rm 이 성공해 exit 0 으로 끝난다. xcframework 없이 통과하고, 아래 -d 가드 때문에
  # 재시도해도 다시 받지 않는다.
  s.prepare_command = <<-CMD
    set -e
    if [ ! -d "Splash.xcframework" ]; then
      curl -fsSL -o Splash.xcframework.zip "https://github.com/sendbird/sendbird-ios-distribution/releases/download/SendbirdSplash-v#{s.version}/Splash.xcframework.zip"
      unzip -oq Splash.xcframework.zip
      rm Splash.xcframework.zip
      test -d "Splash.xcframework"
    fi
  CMD
end
