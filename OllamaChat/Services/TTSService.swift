import Foundation
import AVFoundation

@MainActor
@Observable
final class TTSService {
    
    static let shared = TTSService()
    
    var isSpeaking = false
    var speakingMessageId: UUID? = nil
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentMessageId: UUID? = nil
    
    private init() {
        synthesizer.delegate = nil // Will set self if we add delegate
    }
    
    // MARK: - Speak
    
    func speak(message: ChatMessage) {
        // If already speaking THIS message → stop
        if isSpeaking, speakingMessageId == message.id {
            stop()
            return
        }
        
        // Stop any previous speech
        stop()
        
        guard message.role == "assistant", let content = message.content, !content.isEmpty else { return }
        
        // Strip markdown for cleaner TTS
        let cleanText = stripMarkdown(content)
        guard !cleanText.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        
        // Detect language from content: Korean text → Korean voice, else → device language
        let languageCode = detectLanguage(for: cleanText)
        
        // Try to find a voice for the detected language, fallback to default
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en")
        }
        
        currentMessageId = message.id
        speakingMessageId = message.id
        isSpeaking = true
        
        // Track completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.synthesizer.speak(utterance)
        }
        
        // Use a timer to detect when speech finishes
        startCompletionTimer()
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speakingMessageId = nil
        currentMessageId = nil
        completionTimer?.invalidate()
        completionTimer = nil
    }
    
    // MARK: - Private
    
    private var completionTimer: Timer?
    
    /// Detect language from text content. Returns BCP-47 language code.
    private func detectLanguage(for text: String) -> String {
        // Check for Korean characters (Hangul syllables, Jamo, compatibility Jamo)
        let koreanRange = Character("\u{AC00}")...Character("\u{D7A3}")
        let hasKorean = text.unicodeScalars.contains { scalar in
            let c = Character(scalar)
            return koreanRange.contains(c) || (scalar.value >= 0x3130 && scalar.value <= 0x318F) || (scalar.value >= 0x1100 && scalar.value <= 0x11FF)
        }
        if hasKorean {
            return "ko-KR"
        }
        // Default to device locale language
        return Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    private func startCompletionTimer() {
        completionTimer?.invalidate()
        completionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.synthesizer.isSpeaking {
                    self.isSpeaking = false
                    self.speakingMessageId = nil
                    self.currentMessageId = nil
                    self.completionTimer?.invalidate()
                    self.completionTimer = nil
                }
            }
        }
    }
    
    private func stripMarkdown(_ text: String) -> String {
        var result = text
        
        // Remove code blocks
        result = result.replacingOccurrences(of: "```[\\s\\S]*?```", with: " ", options: .regularExpression)
        // Remove inline code
        result = result.replacingOccurrences(of: "`[^`]+`", with: " ", options: .regularExpression)
        // Remove markdown formatting characters
        result = result.replacingOccurrences(of: "[*_~#>\\[\\]()]", with: "", options: .regularExpression)
        // Remove image links
        result = result.replacingOccurrences(of: "!\\[[^\\]]*\\]\\([^)]*\\)", with: " ", options: .regularExpression)
        // Remove links but keep text
        result = result.replacingOccurrences(of: "\\[([^\\]]*)\\]\\([^)]*\\)", with: "$1", options: .regularExpression)
        // Clean up whitespace
        result = result.replacingOccurrences(of: "\n{2,}", with: ". ", options: .regularExpression)
        result = result.replacingOccurrences(of: "\n", with: ", ")
        result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}