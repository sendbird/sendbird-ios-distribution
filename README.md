# Sendbird CocoaPods Specifications

This repository contains CocoaPods specs and source code for Sendbird AI Agent modules, providing a unified distribution system that simplifies complex multi-module dependencies into a single-line integration.

## 🎯 Quick Start

**For Sendbird AI Agent integration, you only need one line:**

```ruby
pod 'SendbirdAIAgentMessenger', '~> 0.10.0'
```

## ✨ Key Features

- **🎯 Single Line Integration**: Complex 5-module dependency → 1 line in Podfile
- **📦 Dynamic XCFramework Loading**: No large binary files in repository
- **🔒 Namespace Isolation**: Prevents conflicts with other CocoaPods dependencies  
- **🚀 Optimized Distribution**: Private spec repository with coordinated versioning
- **🛠️ Easy Debugging**: Swift source code for all user-facing modules

## Repository Structure

```
├── Sources/                          # Source code and podspecs
│   ├── MarkdownUI/                  # 📝 SwiftUI Markdown rendering
│   ├── NetworkImage/                # 🖼️ Network image loading
│   ├── Splash/                      # ✨ Swift syntax highlighting
│   ├── SendbirdAIAgentCore/         # 🤖 AI Agent Core (XCFramework spec)
│   └── SendbirdAIAgentMessenger/    # 🎯 Main User Module (Swift)
└── Specs/                           # CocoaPods specifications
    ├── SendbirdMarkdownUI/
    ├── SendbirdNetworkImage/
    ├── SendbirdSplash/
    ├── SendbirdAIAgentCore/
    └── SendbirdAIAgentMessenger/    # 🎯 User-facing specs
```

## Modules

### 🎯 SendbirdAIAgentMessenger (v0.10.0) - **USE THIS!**
The main user interface for Sendbird AI Agent
- **Type**: Swift source code (easy to debug)
- **Purpose**: Primary integration point for users
- **Features**: AI conversation, Markdown, syntax highlighting, image loading
- **Dependencies**: All other modules automatically included

### 🤖 SendbirdAIAgentCore (v0.10.0) - **Internal Dependency**
Core AI Agent library with XCFramework
- **Type**: Commercial XCFramework (optimized binary)
- **Source**: Downloaded dynamically from [sendbird-ai-agent-core-ios](https://github.com/sendbird/sendbird-ai-agent-core-ios/releases) releases
- **Purpose**: Internal dependency (users don't directly integrate this)
- **Distribution**: Dynamic download via `prepare_command` - no local storage needed

### 📝 SendbirdMarkdownUI - **Internal Dependency**
Based on [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
- SwiftUI Markdown rendering with GitHub Flavored Markdown support
- Includes swift-cmark dependency for C-level parsing

### 🖼️ SendbirdNetworkImage - **Internal Dependency**
Based on [NetworkImage](https://github.com/gonzalezreal/NetworkImage)
- Asynchronous image loading for SwiftUI
- Persistent and in-memory caching

### ✨ SendbirdSplash - **Internal Dependency**
Based on [Splash](https://github.com/JohnSundell/Splash)
- Swift syntax highlighting
- HTML and NSAttributedString output formats

## 📦 Installation

### Step 1: Add this private spec repository to your Podfile:

```ruby
source 'https://github.com/sendbird/sendbird-cocoapods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  # 🎯 Only integrate this - it includes everything!
  pod 'SendbirdAIAgentMessenger', '~> 0.10.0'
end
```

### Step 2: Install dependencies
```bash
pod install
```

### Step 3: Open your project
```bash
open YourApp.xcworkspace
```

## 🚀 Usage Example

```swift
import SendbirdAIAgentMessenger

// Initialize the AI Agent
AIAgentMessenger.baseInitialize(
    appId: "YOUR_SENDBIRD_APP_ID",
    paramsBuilder: { builder in
        builder.logLevel = .info
        builder.apiHost = "your-api-host"  // Optional
        builder.wsHost = "your-ws-host"    // Optional
    },
    completionHandler: { error in
        if let error = error {
            print("Initialization failed: \(error)")
        } else {
            print("✅ AI Agent initialized successfully!")
        }
    }
)
```

## 🏗️ Architecture

```
📱 User App
└── 🎯 SendbirdAIAgentMessenger (Swift Sources)
    ├── 🤖 SendbirdAIAgentCore (XCFramework)
    ├── 📝 SendbirdMarkdownUI (Swift Sources)
    ├── ✨ SendbirdSplash (Swift Sources)
    └── 🖼️ SendbirdNetworkImage (Swift Sources)
```

## 📄 License

- **Internal Modules**: MIT License (see individual directories)
- **SendbirdAIAgentCore & SendbirdAIAgentMessenger**: Commercial License (Sendbird Inc.)
