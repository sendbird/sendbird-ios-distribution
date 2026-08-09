import Foundation

/// Voice feature entry point, implemented by VoiceKit and called by
/// AIAgentMessenger (or the host app).
///
/// The messenger stores a conformer in `InitializeParams.voiceProvider`;
/// `nil` means voice is not integrated, so the messenger only hides its
/// call UI.
///
/// Incoming calls do not go through this protocol — a VoIP push travels
/// from the app straight into VoiceKit. Outgoing-call requirements
/// (`startCall`) land here when outgoing is implemented.
public protocol VoiceProvider: AnyObject {}
