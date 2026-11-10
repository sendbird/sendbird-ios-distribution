Pod::Spec.new do |s|
  s.name = 'SendbirdMarkdownUI'
  s.version = '1.1.1'
  s.summary = 'Sendbird customized MarkdownUI for SwiftUI'
  s.description = 'A powerful SwiftUI library for displaying and customizing Markdown text, with swift-cmark included, customized for Delight AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdMarkdownUI-v#{s.version}"
  }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  s.module_name = 'SendbirdMarkdownUI'
  
  # Main MarkdownUI sources
  s.source_files = [
    'Sources/MarkdownUI/Sources/**/*.swift',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm/**/*.{c,h,inc}',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/**/*.{c,h}'
  ]
  
  # C headers and include files should be private to avoid umbrella header conflicts
  s.private_header_files = [
    'Sources/MarkdownUI/ThirdParty/cmark-gfm/**/*.h',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/**/*.h',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm/**/*.inc'
  ]
  
  # Exclude CMake and other build files
  s.exclude_files = [
    'Sources/MarkdownUI/ThirdParty/**/CMakeLists.txt',
    'Sources/MarkdownUI/ThirdParty/**/*.re'
  ]
  
  # Preserve modulemap files for C modules
  s.preserve_paths = [
    'Sources/MarkdownUI/ThirdParty/**/module.modulemap'
  ]
  
  # Frameworks
  s.frameworks = 'SwiftUI'
  
  # Internal dependencies
  # 1.0.1 부터 library evolution 으로 빌드한다. 1.0.0 은 그렇지 않아서 하한을 올린다.
  s.dependency 'SendbirdNetworkImage', '~> 1.0', '>= 1.0.1'

  # Compiler flags for C code
  # BUILD_LIBRARY_FOR_DISTRIBUTION: SendbirdAIAgentCore 는 이 모듈을 library evolution 으로
  # 빌드한 것에 맞춰 컴파일된다. 같은 방식으로 빌드하지 않으면 앱이 실행 직후 죽는다.
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm/include $(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/include',
    'OTHER_CFLAGS' => '-DCMARK_GFM_STATIC_DEFINE -DCMARK_THREADING',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
