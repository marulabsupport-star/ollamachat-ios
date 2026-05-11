import Foundation

/// Events emitted during NDJSON streaming
enum StreamEvent: Sendable {
    /// Regular response token
    case token(String)
    /// Thinking/reasoning token (inside think tags)
    case thinking(String)
    /// Stream completed successfully
    case complete
    /// Stream cancelled by user
    case streamCancelled
    /// Stream error
    case error(String)
}