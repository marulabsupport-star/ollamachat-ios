import Foundation
import os.log

/// Singleton managing available model lists.
/// Cloud models are fetched dynamically from the API. Local models are fetched from the Ollama server.
@Observable
final class AvailableModels {
    
    private static let logger = Logger(subsystem: "com.marulab.llmchat", category: "AvailableModels")
    
    static let shared = AvailableModels()
    
    // MARK: - Cloud Models (fetched dynamically)
    
    /// Cloud models fetched from the Ollama Cloud API
    var cloudModels: [DisplayModel] = []
    
    /// Whether cloud models are currently being fetched
    var isLoadingCloud: Bool = false
    
    /// Error from last cloud model fetch
    var cloudError: String?
    
    // MARK: - Local Models (dynamic)
    
    /// Locally available models (fetched from Ollama server)
    var localModels: [DisplayModel] = []
    
    /// Whether local models are currently being fetched
    var isLoadingLocal: Bool = false
    
    /// Error from last local model fetch
    var localError: String?
    
    // MARK: - Combined
    
    /// All models, local first then cloud (for display ordering)
    var allModels: [DisplayModel] {
        localModels + cloudModels
    }
    
    /// Grouped models for picker display: Local then Cloud
    var modelGroups: [(title: String, models: [DisplayModel])] {
        var groups: [(title: String, models: [DisplayModel])] = []
        
        if !localModels.isEmpty {
            groups.append((title: "Local Models", models: localModels))
        }
        
        if !cloudModels.isEmpty {
            groups.append((title: "Cloud Models", models: cloudModels.sorted { $0.displayName < $1.displayName }))
        }
        
        return groups
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Cloud Model Fetching
    
    /// Fetch available models from the Ollama Cloud API
    func fetchCloudModels(apiKey: String) async {
        isLoadingCloud = true
        cloudError = nil
        
        let url = URL(string: "https://api.ollama.com/api/tags")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                cloudError = "Invalid response"
                isLoadingCloud = false
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
                cloudModels = tagsResponse.models.map { model in
                    DisplayModel(
                        id: model.name,
                        displayName: model.name.replacingOccurrences(of: ":latest", with: ""),
                        sizeLabel: model.sizeLabel,
                        connectionMode: "cloud",
                        isCloud: true,
                        supportsVision: model.details?.supportsVision ?? false
                    )
                }
                // Cloud models with empty details: fetch capabilities from /api/show
                // For cloud models, check via Ollama Cloud API
                await fetchCloudVisionCapabilities()
                Self.logger.info("Fetched \(self.cloudModels.count) cloud models")
                
            case 401, 403:
                cloudError = "Invalid API key"
                Self.logger.error("Cloud models fetch: unauthorized (\(httpResponse.statusCode))")
                
            default:
                cloudError = "Server error: \(httpResponse.statusCode)"
                Self.logger.error("Cloud models fetch failed: \(httpResponse.statusCode)")
            }
        } catch {
            cloudError = error.localizedDescription
            Self.logger.error("Cloud models fetch error: \(error.localizedDescription)")
        }
        
        isLoadingCloud = false
    }
    
    /// Fetch vision capabilities for cloud models that lack details
    private func fetchCloudVisionCapabilities() async {
        guard let apiKey = SettingsRepository.shared.ollamaAPIKey, !apiKey.isEmpty else { return }
        let baseURL = URL(string: "https://api.ollama.com")!
        
        for i in cloudModels.indices where !cloudModels[i].supportsVision {
            let hasVision = await fetchVisionCapability(
                modelName: cloudModels[i].id,
                baseURL: baseURL
            )
            if hasVision {
                cloudModels[i] = cloudModels[i].withVisionSupport(true)
            }
        }
    }
    
    // MARK: - Local Model Fetching
    
    /// Fetch available models from a local Ollama server
    func fetchLocalModels(baseURL: URL) async {
        isLoadingLocal = true
        localError = nil
        
        let url = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                localError = "Server returned \(code)"
                isLoadingLocal = false
                return
            }
            
            let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            let displayModels = filterSignificantLocalModels(tagsResponse.models)
            
            // Fetch vision capabilities for each local model
            var updatedModels = displayModels
            for i in updatedModels.indices {
                let hasVision = await fetchVisionCapability(
                    modelName: updatedModels[i].id,
                    baseURL: baseURL
                )
                updatedModels[i] = updatedModels[i].withVisionSupport(hasVision)
            }
            
            localModels = updatedModels
            Self.logger.info("Fetched \(self.localModels.count) local models")
        } catch {
            localError = error.localizedDescription
            Self.logger.error("Local models fetch error: \(error.localizedDescription)")
        }
        
        isLoadingLocal = false
    }
    
    /// Fetch vision capability for a specific model using /api/show
    private func fetchVisionCapability(modelName: String, baseURL: URL) async -> Bool {
        let url = baseURL.appendingPathComponent("api/show")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        
        // Add auth header for cloud models
        if let apiKey = SettingsRepository.shared.ollamaAPIKey, !apiKey.isEmpty, baseURL.host?.contains("ollama.com") == true {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["name": modelName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            let showResponse = try JSONDecoder().decode(OllamaShowResponse.self, from: data)
            return showResponse.supportsVision
        } catch {
            Self.logger.debug("Vision check failed for \(modelName): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Lookup
    
    func isCloudModel(_ modelId: String) -> Bool {
        cloudModels.contains { $0.id == modelId }
    }
    
    func isLocalModel(_ modelId: String) -> Bool {
        localModels.contains { $0.id == modelId }
    }
    
    /// Get display name for a model ID
    func getDisplayName(_ modelId: String) -> String {
        allModels.first { $0.id == modelId }?.displayName ?? modelId
    }
    
    /// Filter local models — only show actually downloaded models.
    /// Uses `isRemote` from OllamaModelInfo to distinguish:
    ///   - Remote/cloud proxy models (remote_model field present) → excluded
    ///   - Locally downloaded models (actual model files) → included
    /// Also excludes embedding models.
    func filterSignificantLocalModels(_ models: [OllamaModelInfo]) -> [DisplayModel] {
        return models
            .filter { model in
                // Skip remote/cloud proxy models — these are served by Ollama cloud, not local
                if model.isRemote { return false }
                // Skip embedding models by name
                let lower = model.name.lowercased()
                if lower.contains("embed") { return false }
                return true
            }
            .map { model in
                DisplayModel(
                    id: model.name,
                    displayName: model.name.replacingOccurrences(of: ":latest", with: ""),
                    sizeLabel: model.sizeLabel,
                    connectionMode: "local",
                    isCloud: false,
                    supportsVision: model.details?.supportsVision ?? false
                )
            }
    }
    
    // MARK: - Model Icons (Emoji)
    
    /// Returns an emoji icon for a model based on its ID.
    static func modelIcon(_ modelId: String) -> String {
        let base = modelId.components(separatedBy: ":").first?.lowercased() ?? modelId.lowercased()
        if base.hasPrefix("gemma") || base.hasPrefix("gemini") { return "🔮" }
        if base.hasPrefix("qwen") { return "🧠" }
        if base.hasPrefix("deepseek") { return "🔍" }
        if base.hasPrefix("mistral") || base.hasPrefix("ministral") { return "🌀" }
        if base.hasPrefix("minimax") { return "✨" }
        if base.hasPrefix("glm") { return "💎" }
        if base.hasPrefix("kimi") { return "🌙" }
        if base.hasPrefix("devstral") { return "⚡" }
        if base.hasPrefix("nemotron") { return "💚" }
        if base.hasPrefix("cogito") { return "🤔" }
        if base.hasPrefix("llama") || base.hasPrefix("llm") { return "🦙" }
        if base.hasPrefix("phi") { return "🔬" }
        if base.hasPrefix("codellama") { return "💻" }
        if base.hasPrefix("command") { return "📡" }
        if base.hasPrefix("starcoder") { return "⭐" }
        // Default
        return "🤖"
    }
}