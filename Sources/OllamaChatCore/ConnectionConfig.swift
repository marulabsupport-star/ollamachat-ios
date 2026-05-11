import Foundation

/// Manages connection configuration for cloud and local Ollama servers.
@Observable
final class ConnectionConfig {
    
    let cloudBaseURL: URL = URL(string: "https://api.ollama.com")!
    
    var localServerURL: String {
        didSet { UserDefaults.standard.set(localServerURL, forKey: "localServerURL") }
    }
    
    var isLocalConfigured: Bool {
        !localServerURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var resolvedLocalURL: URL? {
        normalizeURL(localServerURL)
    }
    
    var activeMode: String = "cloud" {
        didSet { UserDefaults.standard.set(activeMode, forKey: "connectionMode") }
    }
    
    var activeBaseURL: URL {
        switch activeMode {
        case "local":
            return resolvedLocalURL ?? cloudBaseURL
        default:
            return cloudBaseURL
        }
    }
    
    var isCloudAvailable: Bool = false
    var isLocalAvailable: Bool = false
    
    init() {
        self.localServerURL = UserDefaults.standard.string(forKey: "localServerURL") ?? ""
        self.activeMode = UserDefaults.standard.string(forKey: "connectionMode") ?? "cloud"
    }
    
    func switchForModel(_ modelId: String) {
        let isCloud = AvailableModels.shared.isCloudModel(modelId)
        activeMode = isCloud ? "cloud" : "local"
    }
    
    func normalizeURL(_ string: String) -> URL? {
        var trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        trimmed = trimmed
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "file://", with: "")
            .replacingOccurrences(of: "data://", with: "")
            .replacingOccurrences(of: "ftp://", with: "")
        
        if let slashIndex = trimmed.firstIndex(of: "/") {
            trimmed = String(trimmed[..<slashIndex])
        }
        trimmed = trimmed.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else { return nil }
        
        let isIPAddress = trimmed.hasPrefix("192.168.")
            || trimmed.hasPrefix("10.")
            || trimmed.hasPrefix("172.")
        
        let scheme = isIPAddress ? "http" : "https"
        let hasPort = trimmed.contains(":")
        let urlPortion = hasPort ? trimmed : "\(trimmed):11434"
        
        return URL(string: "\(scheme)://\(urlPortion)/")
    }
}