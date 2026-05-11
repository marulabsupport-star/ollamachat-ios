import Foundation

/// Manages connection configuration for cloud and local Ollama servers.
@Observable
final class ConnectionConfig {
    
    // MARK: - Cloud
    
    let cloudBaseURL: URL = URL(string: "https://api.ollama.com")!
    
    // MARK: - Local
    
    var localServerURL: String {
        didSet { UserDefaults.standard.set(localServerURL, forKey: "localServerURL") }
    }
    
    var isLocalConfigured: Bool {
        !localServerURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var resolvedLocalURL: URL? {
        normalizeURL(localServerURL)
    }
    
    // MARK: - Active
    
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
    
    // MARK: - Init
    
    init() {
        self.localServerURL = UserDefaults.standard.string(forKey: "localServerURL") ?? ""
        self.activeMode = UserDefaults.standard.string(forKey: "connectionMode") ?? "cloud"
    }
    
    // MARK: - URL Normalization
    
    /// Normalize a user-entered URL string.
    ///
    /// Rules:
    /// - IP addresses → http://IP:11434 (default Ollama port)
    /// - Hostnames with explicit port → preserve scheme + port
    /// - Hostnames without port (Cloudflare Tunnel, reverse proxy) → https://hostname
    /// - Preserves path if present
    func normalizeURL(_ string: String) -> URL? {
        var trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Add scheme if missing
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            // No scheme — determine default
            let isIP = isIPAddress(trimmed)
            trimmed = isIP ? "http://\(trimmed)" : "https://\(trimmed)"
        }
        
        // Parse with URLComponents
        guard var components = URLComponents(string: trimmed) else { return nil }
        
        // Determine host
        guard let host = components.host, !host.isEmpty else { return nil }
        
        let isIP = isIPAddress(host)
        
        // If no port specified:
        if components.port == nil {
            if isIP {
                // Local IP — default to Ollama port 11434
                components.port = 11434
            }
            // Hostname (Cloudflare Tunnel, etc.) — use default port for scheme (443/80)
        }
        
        // Ensure trailing slash path
        if components.path.isEmpty || components.path == "." {
            components.path = "/"
        }
        // Remove trailing slash from path for consistency, then API calls append paths
        // Actually keep it — base URL should have trailing slash
        
        return components.url
    }
    
    // MARK: - Switching
    
    func switchForModel(_ modelId: String) {
        let isCloud = AvailableModels.shared.isCloudModel(modelId)
        activeMode = isCloud ? "cloud" : "local"
    }
    
    // MARK: - Private Helpers
    
    private func isIPAddress(_ string: String) -> Bool {
        let stripped = string
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
        
        // Match IPv4 or IPv6
        let ipv4Pattern = #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"#
        let ipv6Pattern = #"^\[[0-9a-fA-F:]+\]"#
        
        // Strip port for matching
        let hostPart: String
        if let colonIndex = stripped.firstIndex(of: ":") {
            // Could be port or IPv6 — check if it's IPv6 first
            if stripped.hasPrefix("[") {
                // IPv6 with brackets: [::1]:port or [::1]
                if let closingBracket = stripped.firstIndex(of: "]") {
                    hostPart = String(stripped[...closingBracket])
                } else {
                    hostPart = stripped
                }
            } else {
                hostPart = String(stripped[..<colonIndex])
            }
        } else {
            hostPart = stripped
        }
        
        // Also check common private IP prefixes
        if hostPart.hasPrefix("192.168.") || hostPart.hasPrefix("10.") || hostPart.hasPrefix("172.") {
            return true
        }
        
        return hostPart.matches(regex: ipv4Pattern) || hostPart.matches(regex: ipv6Pattern)
    }
}

private extension String {
    func matches(regex: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return false }
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, range: range) != nil
    }
}