import Foundation
import SwiftData

/// Manages settings screen state.
@MainActor
@Observable
final class SettingsViewModel {
    
    let settingsRepo: SettingsRepository
    
    var settings: AppSettings
    let connectionConfig: ConnectionConfig
    
    // MARK: - UI State
    
    var ollamaKeyInput: String = ""
    var tavilyKeyInput: String = ""
    var localURLInput: String = ""
    var showOllamaKey: Bool = false
    var showTavilyKey: Bool = false
    var saveMessage: String?
    
    // MARK: - Connection Test State
    
    var isTestingConnection: Bool = false
    var connectionTestResult: ConnectionTestResult?
    
    enum ConnectionTestResult {
        case success(String)      // success with model count
        case failure(String)      // error message
        
        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }
    }
    
    var localServerReachable: Bool? {
        switch connectionTestResult {
        case .success: return true
        case .failure: return false
        case nil: return nil
        }
    }
    
    // MARK: - Init
    
    init(settings: AppSettings, connectionConfig: ConnectionConfig, settingsRepo: SettingsRepository = .shared) {
        self.settings = settings
        self.connectionConfig = connectionConfig
        self.settingsRepo = settingsRepo
        
        // Load current values
        self.localURLInput = connectionConfig.localServerURL
        self.ollamaKeyInput = settingsRepo.ollamaAPIKey ?? ""
        self.tavilyKeyInput = settingsRepo.tavilyAPIKey ?? ""
    }
    
    // MARK: - Save Actions
    
    func saveOllamaKey() {
        let key = ollamaKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            settingsRepo.deleteOllamaAPIKey()
            saveMessage = "API key removed"
            return
        }
        do {
            try settingsRepo.saveOllamaAPIKey(key)
            saveMessage = "API key saved ✓"
            // Fetch cloud models with the new key
            Task {
                await AvailableModels.shared.fetchCloudModels(apiKey: key)
            }
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    func saveTavilyKey() {
        let key = tavilyKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            settingsRepo.deleteTavilyAPIKey()
            saveMessage = "Tavily API key removed"
            return
        }
        do {
            try settingsRepo.saveTavilyAPIKey(key)
            saveMessage = "Tavily API key saved"
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    func saveLocalURL() {
        connectionConfig.localServerURL = localURLInput
        saveMessage = "Local server URL saved"
        connectionTestResult = nil
        // Fetch local models with the new URL
        Task {
            if let url = connectionConfig.resolvedLocalURL {
                await AvailableModels.shared.fetchLocalModels(baseURL: url)
            }
        }
    }
    
    // MARK: - Connection Test
    
    func testLocalConnection() async {
        // Save URL first if changed
        if localURLInput != connectionConfig.localServerURL {
            saveLocalURL()
        }
        
        isTestingConnection = true
        connectionTestResult = nil
        
        let apiClient = ApiClient(connectionConfig: connectionConfig)
        
        // First check basic connectivity
        let isReachable = await apiClient.checkLocalServerHealth()
        
        if !isReachable {
            isTestingConnection = false
            connectionTestResult = .failure("Could not reach server. Check the URL and that your server is running.")
            return
        }
        
        // If reachable, try to fetch model list and update AvailableModels
        do {
            let allModels = try await apiClient.fetchLocalModels()
            isTestingConnection = false
            let localModels = AvailableModels.shared.filterSignificantLocalModels(allModels)
            // Update AvailableModels with fetched local models
            AvailableModels.shared.localModels = localModels
            
            if localModels.isEmpty {
                connectionTestResult = .success("Connected! No models installed on this server.")
            } else {
                let modelNames = localModels.prefix(5).map { $0.displayName }.joined(separator: ", ")
                let suffix = localModels.count > 5 ? " and \(localModels.count - 5) more" : ""
                connectionTestResult = .success("Connected! \(localModels.count) model(s): \(modelNames)\(suffix)")
            }
        } catch {
            isTestingConnection = false
            connectionTestResult = .success("Connected! (could not list models)")
        }
    }
    
    func clearAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: ChatSession.self)
            try modelContext.delete(model: ChatMessage.self)
            try modelContext.save()
            saveMessage = "All chat data cleared"
        } catch {
            saveMessage = "Failed to clear: \(error.localizedDescription)"
        }
    }
}