import Foundation

// MARK: - Stream Events

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

// MARK: - Ollama API Models

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let options: OllamaOptions?
    
    init(model: String, messages: [OllamaMessage], stream: Bool = true, options: OllamaOptions? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.options = options
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
    let images: [String]?
    
    enum CodingKeys: String, CodingKey {
        case role, content, images
    }
    
    init(role: String, content: String, images: [String]? = nil) {
        self.role = role
        self.content = content
        self.images = images
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        // Only encode images if present and non-empty
        if let images, !images.isEmpty {
            try container.encode(images, forKey: .images)
        }
    }
}

struct OllamaOptions: Codable {
    let temperature: Double?
    let numPredict: Int?
    let topP: Double?
    let topK: Int?
    
    init(temperature: Double? = nil, numPredict: Int? = nil, topP: Double? = nil, topK: Int? = nil) {
        self.temperature = temperature
        self.numPredict = numPredict
        self.topP = topP
        self.topK = topK
    }
}

struct OllamaStreamLine: Codable {
    let model: String?
    let createdAt: String?
    let message: OllamaStreamMessage?
    let done: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaStreamMessage: Codable {
    let role: String?
    let content: String?
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaModelInfo]
}

struct OllamaModelInfo: Codable {
    let name: String
    let model: String
    let modifiedAt: String?
    let size: Int64?
    let remoteModel: String?
    let remoteHost: String?
    let details: OllamaModelDetails?
    
    enum CodingKeys: String, CodingKey {
        case name, model, size, details
        case modifiedAt = "modified_at"
        case remoteModel = "remote_model"
        case remoteHost = "remote_host"
    }
    
    /// Whether this model runs remotely (Ollama cloud proxy) vs locally downloaded.
    /// A model is remote if it has remote_model field OR if it lacks a real format
    /// (no format = just a stub/proxy, not actual model files downloaded).
    var isRemote: Bool {
        if remoteModel != nil { return true }
        // Models with no format and tiny size are cloud stubs, not local downloads
        if let d = details, d.format.isEmpty, let s = size, s < 1_000_000 { return true }
        return false
    }
    
    var sizeLabel: String? {
        guard let size = size, size > 0 else { return nil }
        let gb = Double(size) / 1_073_741_824.0
        if gb < 0.01 {
            // Very small size likely means remote/proxy model
            return nil
        }
        return String(format: "%.1f GB", gb)
    }
}

struct OllamaModelDetails: Codable {
    let parentModel: String?
    let format: String
    let family: String
    let families: [String]?
    let parameterSize: String
    let quantizationLevel: String
    
    enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
    
    /// Whether this model supports vision, based on families.
    /// Vision models in Ollama have both the text family and "clip" in their families.
    /// e.g. gemma3 has families=["gemma3", "clip"] → supports vision.
    var supportsVision: Bool {
        guard let families, !families.isEmpty else { return false }
        return families.contains("clip")
    }
}

struct OllamaShowResponse: Codable {
    let details: OllamaModelDetails?
    let capabilities: [String]?
    let modelInfo: [String: StringValue]?
    
    enum CodingKeys: String, CodingKey {
        case details, capabilities
        case modelInfo = "model_info"
    }
    
    /// Whether this model supports vision
    var supportsVision: Bool {
        // Check capabilities first (most reliable)
        if let caps = capabilities, caps.contains("vision") {
            return true
        }
        // Fallback: check details.families for "clip"
        if let details, details.supportsVision {
            return true
        }
        return false
    }
}

/// Wrapper for flexible JSON value decoding in model_info
struct StringValue: Codable {
    let stringValue: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            stringValue = s
        } else if let i = try? container.decode(Int.self) {
            stringValue = String(i)
        } else if let d = try? container.decode(Double.self) {
            stringValue = String(d)
        } else {
            stringValue = try container.decode(String.self)
        }
    }
}

struct TavilySearchRequest: Codable {
    let apiKey: String
    let query: String
    let maxResults: Int?
    
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case query
        case maxResults = "max_results"
    }
}

struct TavilySearchResponse: Codable {
    let results: [TavilyResult]
}

struct TavilyResult: Codable, Identifiable {
    let title: String
    let url: String
    let content: String
    let score: Double?
    
    var id: String { url }
}

// MARK: - Backup/Restore Models

struct BackupData: Codable {
    let version: Int
    let exportedAt: Date
    let sessions: [BackupSession]
    
    static let currentVersion = 1
}

struct BackupSession: Codable {
    let id: UUID
    let title: String
    let modelName: String
    let connectionMode: String
    let systemPrompt: String
    let pinned: Bool
    let createdAt: Date
    let updatedAt: Date
    let messages: [BackupMessage]
}

struct BackupMessage: Codable {
    let id: UUID
    let role: String
    let content: String?
    let thinkingContent: String?
    let createdAt: Date
}
