# Delight AI Agent Messenger

The primary interface for Delight AI Agent with advanced messaging capabilities.

## 🎯 This is the main module that users should integrate!

## Features

- **🤖 AI Conversation**: Advanced AI-powered messaging
- **📝 Markdown Rendering**: Rich text support with MarkdownUI
- **✨ Syntax Highlighting**: Code highlighting with Splash
- **🖼️ Image Loading**: Network image support with NetworkImage
- **🔧 Easy Integration**: Simple Swift API

## Installation

Add the private spec repository to your Podfile:

```ruby
source 'https://github.com/sendbird/sendbird-ios-distribution.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  pod 'SendbirdAIAgentMessenger', '>= 1.11.1'
end
```

## Quick Start

```swift
import SendbirdAIAgentMessenger

// Initialize configuration
let config = MessengerConfiguration(
    applicationId: "YOUR_APP_ID",
    apiKey: "YOUR_API_KEY",
    debugMode: true
)

// Initialize the messenger
SendbirdAIAgentMessenger.shared.initialize(with: config)

// Send a message
SendbirdAIAgentMessenger.shared.sendMessage("Hello AI!") { response in
    if response.success {
        print("Response: \(response.message)")
    } else {
        print("Error: \(response.error?.localizedDescription ?? "Unknown error")")
    }
}

// Check capabilities
let capabilities = SendbirdAIAgentMessenger.shared.getCapabilities()
print("Supported features: \(capabilities)")
```

## Architecture

```
SendbirdAIAgentMessenger (Swift Sources) 🎯 <- Users integrate this
├── SendbirdAIAgentCore (XCFramework)      <- Internal dependency
├── SendbirdMarkdownUI (Swift Sources)     <- Markdown rendering
├── SendbirdSplash (Swift Sources)         <- Syntax highlighting  
└── SendbirdNetworkImage (Swift Sources)   <- Image loading
```

## Dependencies

This library automatically includes:
- SendbirdAIAgentCore (pre-built XCFramework)
- SendbirdMarkdownUI (SwiftUI Markdown rendering)
- SendbirdSplash (Swift syntax highlighting)
- SendbirdNetworkImage (Network image loading)
- SendbirdUIMessageTemplate (Message templates)

## License

Commercial - Sendbird Inc.
