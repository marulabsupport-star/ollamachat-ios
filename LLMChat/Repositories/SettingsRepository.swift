import Foundation
import Security
import os.log

/// Detects whether the app is running on a simulator.
enum TargetPlatform {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

/// Manages API keys — uses UserDefaults on simulator (reliable), Keychain on real devices (secure).
/// On simulator, Keychain has known persistence issues across reinstalls and access group mismatches.
/// UserDefaults avoids all of these problems while being perfectly fine for development/testing.
/// On real devices, Keychain with biometric access control is the correct secure storage.
final class SettingsRepository {
    
    private static let logger = Logger(subsystem: "com.marulab.llmchat", category: "SettingsRepository")
    
    // MARK: - Keychain Constants (device only)
    
    private let ollamaKeyService = "com.marulab.llmchat.ollama-key"
    private let tavilyKeyService = "com.marulab.llmchat.tavily-key"
    private let keychainAccount = "api-key"
    
    // MARK: - UserDefaults Keys (simulator fallback + verification)
    
    private let ollamaKeyUD = "ollama-cloud-api-key"
    private let tavilyKeyUD = "tavily-api-key"
    
    // MARK: - Singleton
    
    static let shared = SettingsRepository()
    private init() {}
    
    // MARK: - Ollama Cloud API Key
    
    var ollamaAPIKey: String? {
        if TargetPlatform.isSimulator {
            return UserDefaults.standard.string(forKey: ollamaKeyUD)
        }
        return keychainLoad(service: ollamaKeyService)
    }
    
    func saveOllamaAPIKey(_ key: String) throws {
        if TargetPlatform.isSimulator {
            UserDefaults.standard.set(key, forKey: ollamaKeyUD)
            Self.logger.info("Ollama key saved to UserDefaults (simulator)")
            return
        }
        try keychainSave(key, service: ollamaKeyService)
    }
    
    func deleteOllamaAPIKey() {
        if TargetPlatform.isSimulator {
            UserDefaults.standard.removeObject(forKey: ollamaKeyUD)
            return
        }
        keychainDelete(service: ollamaKeyService)
    }
    
    var hasOllamaAPIKey: Bool {
        ollamaAPIKey != nil
    }
    
    // MARK: - Tavily API Key
    
    var tavilyAPIKey: String? {
        if TargetPlatform.isSimulator {
            return UserDefaults.standard.string(forKey: tavilyKeyUD)
        }
        return keychainLoad(service: tavilyKeyService)
    }
    
    func saveTavilyAPIKey(_ key: String) throws {
        if TargetPlatform.isSimulator {
            UserDefaults.standard.set(key, forKey: tavilyKeyUD)
            Self.logger.info("Tavily key saved to UserDefaults (simulator)")
            return
        }
        try keychainSave(key, service: tavilyKeyService)
    }
    
    func deleteTavilyAPIKey() {
        if TargetPlatform.isSimulator {
            UserDefaults.standard.removeObject(forKey: tavilyKeyUD)
            return
        }
        keychainDelete(service: tavilyKeyService)
    }
    
    var hasTavilyAPIKey: Bool {
        tavilyAPIKey != nil
    }
    
    // MARK: - Keychain Operations (real devices only)
    
    private func keychainSave(_ key: String, service: String) throws {
        let keyData = Data(key.utf8)
        
        // Update-first pattern: try update, then add if not found
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            Self.logger.info("Keychain update succeeded: \(service)")
            return
        }
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist yet — add it
            var addQuery = query
            addQuery[kSecValueData as String] = keyData
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            Self.logger.info("Keychain add: \(service), status=\(addStatus)")
            
            guard addStatus == errSecSuccess else {
                let msg = SecCopyErrorMessageString(addStatus, nil) as String? ?? "status \(addStatus)"
                Self.logger.error("Keychain add failed: \(msg)")
                throw OllamaError.unexpected("Failed to save API key: \(msg)")
            }
            return
        }
        
        let msg = SecCopyErrorMessageString(updateStatus, nil) as String? ?? "status \(updateStatus)"
        Self.logger.error("Keychain update failed: \(msg)")
        throw OllamaError.unexpected("Failed to save API key: \(msg)")
    }
    
    private func keychainLoad(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        Self.logger.info("Keychain load: \(service), status=\(status)")
        
        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                Self.logger.warning("Keychain load failed: status=\(status)")
            }
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func keychainDelete(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Self.logger.warning("Keychain delete failed: \(service), status=\(status)")
        }
    }
}