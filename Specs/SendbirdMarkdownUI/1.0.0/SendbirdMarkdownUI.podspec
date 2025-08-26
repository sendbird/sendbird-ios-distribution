Pod::Spec.new do |s|
  s.name = 'SendbirdMarkdownUI'
  s.version = '1.0.1'
  s.summary = 'Sendbird customized MarkdownUI for SwiftUI'
  s.description = 'A powerful SwiftUI library for displaying and customizing Markdown text, with swift-cmark included, customized for Sendbird AI Agent'
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
  s.dependency 'SendbirdNetworkImage', '~> 1.0'
  
  # Compiler flags for C code
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm/include $(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/include',
    'OTHER_CFLAGS' => '-DCMARK_GFM_STATIC_DEFINE -DCMARK_THREADING'
  }
end
