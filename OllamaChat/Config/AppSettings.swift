import Foundation
import SwiftUI

/// App-wide settings managed via UserDefaults.
/// API keys are NOT here — they go in Keychain via SettingsRepository.
@Observable
final class AppSettings {
    
    // MARK: - Theme
    
    var themeMode: String {
        didSet { UserDefaults.standard.set(themeMode, forKey: "themeMode") }
    }
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system
        }
    }
    
    // MARK: - Chat Defaults
    
    var defaultModel: String {
        didSet { UserDefaults.standard.set(defaultModel, forKey: "defaultModel") }
    }
    
    var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt") }
    }
    
    var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: "temperature") }
    }
    
    var maxTokens: Int {
        didSet { UserDefaults.standard.set(maxTokens, forKey: "maxTokens") }
    }
    
    // MARK: - Display
    
    var showWelcomeCard: Bool {
        didSet { UserDefaults.standard.set(showWelcomeCard, forKey: "showWelcomeCard") }
    }
    
    var showThinkingByDefault: Bool {
        didSet { UserDefaults.standard.set(showThinkingByDefault, forKey: "showThinkingByDefault") }
    }
    
    // MARK: - Web Search
    
    /// Search mode: "off" = never, "auto" = AI decides, "always" = every message
    var webSearchMode: String {
        didSet { UserDefaults.standard.set(webSearchMode, forKey: "webSearchMode") }
    }
    
    // MARK: - Follow-up Suggestions
    
    /// Whether to append follow-up suggestion instruction to system prompt
    var followUpSuggestions: Bool {
        didSet { UserDefaults.standard.set(followUpSuggestions, forKey: "followUpSuggestions") }
    }
    
    // MARK: - Privacy Consent
    
    var privacyConsentGiven: Bool {
        didSet { UserDefaults.standard.set(privacyConsentGiven, forKey: "privacyConsentGiven") }
    }
    
    static func markPrivacyConsentGiven() {
        UserDefaults.standard.set(true, forKey: "privacyConsentGiven")
    }
    
    static func hasPrivacyConsent() -> Bool {
        UserDefaults.standard.bool(forKey: "privacyConsentGiven")
    }
    
    // MARK: - Init
    
    init() {
        self.themeMode = UserDefaults.standard.string(forKey: "themeMode") ?? "system"
        self.defaultModel = UserDefaults.standard.string(forKey: "defaultModel") ?? ""
        self.systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? ""
        self.temperature = UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7
        self.maxTokens = UserDefaults.standard.object(forKey: "maxTokens") as? Int ?? 2048
        self.showWelcomeCard = UserDefaults.standard.object(forKey: "showWelcomeCard") as? Bool ?? true
        self.showThinkingByDefault = UserDefaults.standard.object(forKey: "showThinkingByDefault") as? Bool ?? false
        self.webSearchMode = UserDefaults.standard.string(forKey: "webSearchMode") ?? "auto"
        self.followUpSuggestions = UserDefaults.standard.object(forKey: "followUpSuggestions") as? Bool ?? false
        self.privacyConsentGiven = UserDefaults.standard.bool(forKey: "privacyConsentGiven")
    }
}