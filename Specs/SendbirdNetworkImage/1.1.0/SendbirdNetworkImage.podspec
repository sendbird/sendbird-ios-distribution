Pod::Spec.new do |s|
  s.name = 'SendbirdNetworkImage'
  s.version = '1.1.0'
  s.summary = 'Sendbird customized NetworkImage for SwiftUI'
  s.description = 'An image loading library for SwiftUI, customized for Delight AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'Licenses/SendbirdNetworkImage-NOTICE.txt' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }

  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdNetworkImage-v#{s.version}"
  }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'SendbirdNetworkImage'

  # Xcode 27 의 iOS SDK 는 최소 배포 타깃이 15.0 이라 소스를 iOS 14 로 빌드하지
  # 못한다. 그러면 SendbirdAIAgentCore 의 ios14.0 swiftinterface 를 재컴파일할 때
  # 실패한다. 이 xcframework 의 swiftinterface 는 ios14.0 으로 고정돼 있다.
  # scripts/build_xcframeworks.sh 가 Xcode 26 으로 만든다.
  s.ios.vendored_frameworks = 'SendbirdNetworkImage.xcframework'

  s.frameworks = 'SwiftUI', 'Combine'

  s.prepare_command = <<-CMD
    if [ ! -d "SendbirdNetworkImage.xcframework" ]; then
      curl -fsSL -o SendbirdNetworkImage-cocoapods.xcframework.zip "https://github.com/sendbird/sendbird-ios-distribution/releases/download/0.11.0/SendbirdNetworkImage-cocoapods.xcframework.zip"
      unzip -oq SendbirdNetworkImage-cocoapods.xcframework.zip
      rm SendbirdNetworkImage-cocoapods.xcframework.zip
    fi
  CMD
end
