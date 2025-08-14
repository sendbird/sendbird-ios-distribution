# Sendbird Private CocoaPods Repository

This repository contains CocoaPods specifications and source code for Sendbird's private pod modules, providing streamlined distribution and dependency management for Sendbird SDK components.

## Repository Structure

```
├── Sources/                          # Source code and podspecs
│   ├── MarkdownUI/                   # SwiftUI Markdown rendering
│   ├── NetworkImage/                 # Network image loading
│   ├── Splash/                       # Swift syntax highlighting
│   ├── SendbirdAIAgentCore/          # AI Agent Core (XCFramework spec)
│   └── SendbirdAIAgentMessenger/     # AI Agent Messenger (Swift)
└── Specs/                            # CocoaPods specifications
    ├── SendbirdMarkdownUI/
    ├── SendbirdNetworkImage/
    ├── SendbirdSplash/
    ├── SendbirdAIAgentCore/
    └── SendbirdAIAgentMessenger/
```

## AI Agent Integration

The AI Agent modules provide conversational AI capabilities for iOS applications.

### SendbirdAIAgentMessenger
The primary integration point for Sendbird AI Agent functionality.
- **Type**: Swift source code
- **Features**: AI conversation, Markdown rendering, syntax highlighting, image loading
- **Dependencies**: Automatically includes all required modules

### SendbirdAIAgentCore
Core AI Agent library with XCFramework distribution.
- **Type**: Commercial XCFramework (optimized binary)
- **Source**: Downloaded dynamically from [sendbird-ai-agent-core-ios](https://github.com/sendbird/sendbird-ai-agent-core-ios/releases) releases
- **Distribution**: Dynamic download via `prepare_command` - no local storage needed

### Usage

For detailed usage instructions, examples, and API documentation, please refer to the [Sendbird AI Agent iOS documentation](https://github.com/sendbird/sendbird-ai-agent/tree/main/ios).

## Installation

### Step 1: Configure your Podfile
Add the private spec repository and configure post-install settings:

```ruby
source 'https://github.com/sendbird/sendbird-ios-distribution.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  pod 'SendbirdAIAgentMessenger', '~> 0.10.2'
end

# Required for XCFramework download scripts
post_install do |installer|
  project = installer.aggregate_targets[0].user_project
  project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
  end
  project.save
end
```

**Note**: The `post_install` hook disables user script sandboxing, which is required for the XCFramework download scripts used by `SendbirdAIAgentCore` to function properly.

## Troubleshooting

### Framework Search Path Issues

If you encounter build errors related to framework search paths or rsync errors, check your project's `FRAMEWORK_SEARCH_PATHS` setting:

1. Open your project in Xcode
2. Select your target → Build Settings → Search Paths → Framework Search Paths
3. Ensure the value is not empty (`""`)
4. If empty, set it to `$(inherited)` or remove the custom setting to use default values

**Common symptoms:**
- Build errors mentioning missing frameworks
- rsync command failures during build
- "Framework not found" linker errors

This issue can occur when `FRAMEWORK_SEARCH_PATHS` is explicitly set to empty in your project settings, preventing CocoaPods from properly locating framework dependencies.

### Step 2: Install
```bash
pod install
```

## Open Source Dependencies

This repository includes forks of the following open source projects, adapted for Sendbird's ecosystem:

### SendbirdMarkdownUI
Fork of [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
- SwiftUI Markdown rendering with GitHub Flavored Markdown support
- Includes swift-cmark dependency for C-level parsing

### SendbirdNetworkImage
Fork of [NetworkImage](https://github.com/gonzalezreal/NetworkImage)
- Asynchronous image loading for SwiftUI
- Persistent and in-memory caching

### SendbirdSplash
Fork of [Splash](https://github.com/JohnSundell/Splash)
- Swift syntax highlighting
- HTML and NSAttributedString output formats

## License

- **Open Source Forks** (SendbirdMarkdownUI, SendbirdNetworkImage, SendbirdSplash): MIT License
- **AI Agent Modules**: Commercial License (Sendbird Inc.)
