Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '0.10.0'
  s.summary = 'Sendbird AI Agent Core Library'
  s.description = 'Core library for Sendbird AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentCore/LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  # GitHub source with XCFramework download
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "SendbirdAIAgentCore-v#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # XCFramework from local path (will be available after git clone)
  s.ios.vendored_frameworks = 'Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '~> 3.32.1'
  s.dependency 'SendbirdChatSDK', '~> 4.29.2'
  
  # Download XCFramework from GitHub releases
  s.prepare_command = <<-CMD
    if [ ! -d "Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework" ]; then
      echo "Downloading SendbirdAIAgentCore XCFramework from GitHub releases..."
      curl -L -o SendbirdAIAgentCore.xcframework.zip "https://github.com/sendbird/sendbird-ai-agent-core-ios/releases/download/#{s.version}/SendbirdAIAgentCore.xcframework.zip"
      unzip -o SendbirdAIAgentCore.xcframework.zip -d Sources/SendbirdAIAgentCore/
      rm SendbirdAIAgentCore.xcframework.zip
    fi
  CMD
  
  # Build settings to handle Swift version compatibility
  s.pod_target_xcconfig = {
    'SWIFT_SUPPRESS_WARNINGS' => 'YES',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
    'SWIFT_VERSION' => '5.7'
  }
end
