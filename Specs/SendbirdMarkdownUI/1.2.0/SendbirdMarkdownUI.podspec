Pod::Spec.new do |s|
  s.name = 'SendbirdMarkdownUI'
  s.version = '1.2.0'
  s.summary = 'Sendbird customized MarkdownUI for SwiftUI'
  s.description = 'A powerful SwiftUI library for displaying and customizing Markdown text, with swift-cmark included, customized for Delight AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'Licenses/SendbirdMarkdownUI-NOTICE.txt' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }

  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdMarkdownUI-v#{s.version}"
  }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'SendbirdMarkdownUI'

  # Xcode 27 의 iOS SDK 는 최소 배포 타깃이 15.0 이라 소스를 iOS 14 로 빌드하지
  # 못한다. 그러면 SendbirdAIAgentCore 의 ios14.0 swiftinterface 를 재컴파일할 때
  # "module 'SendbirdMarkdownUI' has a minimum deployment target of iOS 15.0" 으로
  # 실패한다. 이 xcframework 의 swiftinterface 는 ios14.0 으로 고정돼 있다.
  #
  # cmark-gfm C 코드는 이 바이너리 안에 정적으로 흡수돼 있어서, 예전에 필요하던
  # private_header_files / preserve_paths / SWIFT_INCLUDE_PATHS 설정이 없어졌다.
  s.ios.vendored_frameworks = 'SendbirdMarkdownUI.xcframework'

  s.frameworks = 'SwiftUI'

  s.dependency 'SendbirdNetworkImage', '~> 1.1'

  # set -e 와 test 가 없으면, 프록시가 200 으로 HTML 을 주는 경우 unzip 이 실패해도
  # rm 이 성공해 exit 0 으로 끝난다. xcframework 없이 통과하고, 아래 -d 가드 때문에
  # 재시도해도 다시 받지 않는다.
  s.prepare_command = <<-CMD
    set -e
    if [ ! -d "SendbirdMarkdownUI.xcframework" ]; then
      curl -fsSL -o SendbirdMarkdownUI.xcframework.zip "https://github.com/sendbird/sendbird-ios-distribution/releases/download/SendbirdMarkdownUI-v#{s.version}/SendbirdMarkdownUI.xcframework.zip"
      unzip -oq SendbirdMarkdownUI.xcframework.zip
      rm SendbirdMarkdownUI.xcframework.zip
      test -d "SendbirdMarkdownUI.xcframework"
    fi
  CMD
end
