import Foundation

/// Namespace for ExtensionKit module metadata.
///
/// ExtensionKit is the cross-SDK shared interface module:
/// - Protocols and value types only. No implementation code, no UI,
///   no networking, and no dependencies on other Sendbird SDKs.
/// - Additive-only evolution: new protocol requirements must ship with
///   default implementations so that existing conformers keep compiling.
///
/// The contract between AIAgentMessenger and VoiceKit lives here as two
/// protocols facing opposite directions: `VoiceProvider` (VoiceKit conforms,
/// messenger calls) and `VoiceHTTPSender` (messenger conforms, VoiceKit calls).
public enum ExtensionKitInfo {
    /// The version of this module.
    public static let version = "0.1.0"
}
