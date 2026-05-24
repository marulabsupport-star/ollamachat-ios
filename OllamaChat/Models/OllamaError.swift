import Foundation

/// All app errors, categorized for UI presentation
enum OllamaError: LocalizedError {
    // Network
    case networkUnavailable
    case serverUnreachable(url: String)
    case timeout(seconds: Double)
    case httpError(statusCode: Int, message: String)
    case rateLimited
    
    // Streaming
    case streamInterrupted
    case streamParseError(line: String)
    case streamCancelled
    
    // Auth
    case apiKeyMissing
    case apiKeyInvalid
    case biometricAuthFailed
    
    // Data
    case dataCorruption(context: String)
    case backupImportFailed(reason: String)
    case backupVersionUnsupported(version: Int)
    
    // Validation
    case invalidURL(url: String)
    case fileTooLarge(size: Int64, max: Int64)
    case unsupportedFileType(mimeType: String)
    
    // General
    case unexpected(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection"
        case .serverUnreachable(let url):
            return "Can't reach server at \(url)"
        case .timeout(let seconds):
            return "Request timed out after \(Int(seconds)) seconds"
        case .httpError(let code, let message):
            return "Server error \(code): \(message)"
        case .rateLimited:
            return "Rate limited — please wait and try again"
        case .streamInterrupted:
            return "Connection lost during response"
        case .streamParseError:
            return "Error parsing server response"
        case .streamCancelled:
            return "Request cancelled"
        case .apiKeyMissing:
            return "API key required for cloud access"
        case .apiKeyInvalid:
            return "Invalid API key"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .dataCorruption(let context):
            return "Data error: \(context)"
        case .backupImportFailed(let reason):
            return "Import failed: \(reason)"
        case .backupVersionUnsupported(let version):
            return "Unsupported backup version: \(version)"
        case .invalidURL(let url):
            return "Invalid server URL: \(url)"
        case .fileTooLarge(let size, let max):
            return "File too large (\(size / 1_048_576)MB, max \(max / 1_048_576)MB)"
        case .unsupportedFileType(let mimeType):
            return "Unsupported file type: \(mimeType)"
        case .unexpected(let message):
            return message
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serverUnreachable, .timeout, .rateLimited, .streamInterrupted:
            return true
        default:
            return false
        }
    }
}