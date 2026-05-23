import Foundation

// Sealed result for a complete chat response
struct ChatResponse: Codable {
    let model: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
    }
}

/// Ollama API request models
struct LLMChatRequest: Codable {
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
    
    init(role: String, content: String, images: [String]? = nil) {
        self.role = role
        self.content = content
        self.images = images
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

/// NDJSON streaming response line
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

/// Ollama tags response (for fetching local models)
struct OllamaTagsResponse: Codable {
    let models: [OllamaModelInfo]
}

struct OllamaModelInfo: Codable {
    let name: String
    let model: String
    let modifiedAt: String?
    let size: Int64?
    
    enum CodingKeys: String, CodingKey {
        case name, model
        case modifiedAt = "modified_at"
        case size
    }
    
    var sizeLabel: String? {
        guard let size = size, size > 0 else { return nil }
        let gb = Double(size) / 1_073_741_824.0
        return String(format: "%.1f GB", gb)
    }
}

/// Tavily search models
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

/// Backup/restore models
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

/// Display model for UI
struct DisplayModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let sizeLabel: String?
    let connectionMode: String
    let isCloud: Bool
    
    var subtitle: String {
        if let size = sizeLabel {
            return isCloud ? "Cloud • \(size)" : "Local • \(size)"
        }
        return isCloud ? "Cloud" : "Local"
    }
}