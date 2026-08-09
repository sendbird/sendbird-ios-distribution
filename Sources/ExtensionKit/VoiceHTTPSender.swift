import Foundation

/// HTTP transport pipe, implemented by AIAgentMessenger and called by VoiceKit.
///
/// VoiceKit cannot import the auth SDK, so it reaches the messenger's
/// RequestQueue through this protocol. The queue injects session headers,
/// refreshes an expired session and replays the request; VoiceKit keeps
/// request building and response decoding.
///
/// Required at `Voice.initialize(httpSender:)` — there is no state where a
/// sender is missing. The only production conformer is the messenger's
/// `VoiceQueueHTTPSender`; unit tests inject a mock.
public protocol VoiceHTTPSender: AnyObject {
    /// Whether a valid authenticated user session exists.
    ///
    /// VoiceKit never looks at the session itself. It reads this one bit to
    /// decide whether to skip the session token exchange: `true` sends over
    /// the queue's user session, `false` exchanges the short-lived token that
    /// came in the ringing push first.
    var hasValidSession: Bool { get }

    /// Sends a request and returns the raw response.
    ///
    /// The completion may run on any queue.
    func send(
        _ request: VoiceHTTPRequest,
        completion: @escaping (Result<VoiceHTTPResponse, Error>) -> Void
    )
}

/// A request handed to `VoiceHTTPSender`.
public struct VoiceHTTPRequest {
    /// HTTP method, e.g. `"POST"`.
    public let method: String

    /// Only the path is used — the host comes from the sender's queue.
    public let url: URL

    /// Per-request authentication headers, such as the short-lived session key.
    public let headers: [String: String]

    public let body: Data?

    public init(
        method: String,
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

/// A response returned by `VoiceHTTPSender`, left undecoded on purpose:
/// interpreting the body belongs to VoiceKit.
public struct VoiceHTTPResponse {
    public let statusCode: Int
    public let body: Data

    public init(statusCode: Int, body: Data) {
        self.statusCode = statusCode
        self.body = body
    }
}
