import Foundation
import Security

/// Manages API keys in Keychain. Not actor-isolated — thread-safe via Keychain's own serialization.
final class SettingsRepository {
    
    private let ollamaKeyService = "com.marulab.llmchat.ollama-key"
    private let tavilyKeyService = "com.marulab.llmchat.tavily-key"
    private let keychainAccount = "api-key"
    
    static let shared = SettingsRepository()
    private init() {}
    
    var ollamaAPIKey: String? { loadKey(service: ollamaKeyService) }
    var hasOllamaAPIKey: Bool { ollamaAPIKey != nil }
    var tavilyAPIKey: String? { loadKey(service: tavilyKeyService) }
    var hasTavilyAPIKey: Bool { tavilyAPIKey != nil }
    
    func saveOllamaAPIKey(_ key: String) throws {
        try saveKey(key, service: ollamaKeyService)
    }
    
    func deleteOllamaAPIKey() { deleteKey(service: ollamaKeyService) }
    
    func saveTavilyAPIKey(_ key: String) throws {
        try saveKey(key, service: tavilyKeyService)
    }
    
    func deleteTavilyAPIKey() { deleteKey(service: tavilyKeyService) }
    
    // MARK: - Keychain Operations
    
    private func saveKey(_ key: String, service: String) throws {
        deleteKey(service: service)
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: Data(key.utf8),
            kSecAttrAccessControl as String: access as Any,
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let errMsg = SecCopyErrorMessageString(status, nil) as String? ?? "unknown error"
            throw OllamaError.unexpected("Failed to save API key: \(errMsg)")
        }
    }
    
    private func loadKey(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteKey(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}