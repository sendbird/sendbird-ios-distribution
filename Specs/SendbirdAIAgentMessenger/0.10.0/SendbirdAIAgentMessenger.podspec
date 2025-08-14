Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentMessenger'
  s.version = '0.10.0'
  s.summary = 'Sendbird AI Agent Messenger - Main User Interface'
  s.description = 'The primary interface for Sendbird AI Agent with Markdown rendering, syntax highlighting, and advanced messaging capabilities. This is what users should integrate.'
  s.homepage = 'https://github.com/sendbird/sendbird-ios-distribution'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentMessenger/LICENSE' }
  s.author = { 'Tez Park' => 'tez.park@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-ios-distribution.git',
    :tag => "SendbirdAIAgentMessenger-v#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # Swift source files
  s.source_files = 'Sources/SendbirdAIAgentMessenger/Sources/**/*.swift'
  
  # Internal dependencies (from same private repo)
  s.dependency 'SendbirdAIAgentCore', '0.10.0'
  s.dependency 'SendbirdMarkdownUI', '1.0.0'
  s.dependency 'SendbirdSplash', '1.0.0'
  s.dependency 'SendbirdNetworkImage', '1.0.0'
  
  # Frameworks
  s.frameworks = 'Foundation', 'SwiftUI', 'Combine'
end
