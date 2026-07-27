import Foundation

/// Namespace for ExtensionKit module metadata.
///
/// ExtensionKit is the cross-SDK shared interface module:
/// - Protocols and value types only. No implementation code, no UI,
///   no networking, and no dependencies on other Sendbird SDKs.
/// - Additive-only evolution: new protocol requirements must ship with
///   default implementations so that existing conformers keep compiling.
///
/// VoiceProtocol (the contract between AIAgentMessenger and VoiceKit)
/// will be declared in this module.
public enum ExtensionKitInfo {
    /// The version of this module.
    public static let version = "0.1.0"
}
