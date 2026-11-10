Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '1.24.1'
  s.summary = 'Delight AI Agent Core Library'
  s.description = 'Core library for Delight AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentCore/LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  # GitHub source with XCFramework download
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdAIAgentCore-v#{s.version}"
  }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.7'
  
  # XCFramework from local path (will be available after git clone)
  s.ios.vendored_frameworks = 'Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '>= 3.36.4', '< 4.0'
  s.dependency 'SendbirdChatSDK', '>= 4.39.13', '< 5.0'
  
  # Core links these three as dynamic frameworks (@rpath), built with library evolution.
  # Messenger pulls them too, but a Core-only Podfile must not lose the dylibs.
  s.dependency 'SendbirdMarkdownUI', '~> 1.1.1'
  s.dependency 'SendbirdNetworkImage', '1.0.1'
  s.dependency 'SendbirdSplash', '1.0.1'
  
  # Download XCFramework from GitHub releases
  s.prepare_command = <<-CMD
    if [ ! -d "Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework" ]; then
      echo "Downloading SendbirdAIAgentCore XCFramework from GitHub releases..."
      curl -L -o SendbirdAIAgentCore.xcframework.zip "https://github.com/sendbird/delight-ai-agent-core-ios/releases/download/#{s.version}/SendbirdAIAgentCore.xcframework.zip"
      unzip -o SendbirdAIAgentCore.xcframework.zip -d Sources/SendbirdAIAgentCore/
      rm SendbirdAIAgentCore.xcframework.zip
    fi
  CMD
end
