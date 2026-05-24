import Foundation

/// Provides brand attribution for known AI model families.
/// This ensures proper credit to model creators and clarifies that
/// OllamaChat is a client app — not the creator of these models.
enum ModelAttribution {
    
    /// Known model family prefixes and their brand attributions.
    /// Model IDs from Ollama typically look like "llama3.2:1b", "gemma2:9b", etc.
    /// We match on the prefix before any version/size delimiter.
    private static let families: [(prefix: String, attribution: String)] = [
        // Meta models
        ("llama",    "by Meta"),
        ("llama2",   "by Meta"),
        ("llama3",   "by Meta"),
        ("llama3.1", "by Meta"),
        ("llama3.2", "by Meta"),
        ("llama3.3", "by Meta"),
        ("llama4",   "by Meta"),
        // Google models
        ("gemma",    "by Google"),
        ("gemma2",   "by Google"),
        ("gemma3",   "by Google"),
        ("codegemma", "by Google"),
        // Mistral models
        ("mistral",  "by Mistral AI"),
        ("mixtral",  "by Mistral AI"),
        ("codestral","by Mistral AI"),
        // Alibaba models
        ("qwen",     "by Alibaba"),
        ("qwen2",    "by Alibaba"),
        ("qwen3",    "by Alibaba"),
        // Microsoft models
        ("phi",      "by Microsoft"),
        ("phi2",     "by Microsoft"),
        ("phi3",     "by Microsoft"),
        ("phi4",     "by Microsoft"),
        // Cohere models
        ("command",  "by Cohere"),
        ("command-r","by Cohere"),
        // DeepSeek models
        ("deepseek", "by DeepSeek"),
        ("deepseek-coder", "by DeepSeek"),
        // Anthropic models (unlikely via Ollama, but just in case)
        ("claude",   "by Anthropic"),
    ]
    
    /// Returns attribution string for a model ID, or nil if unknown.
    /// Model IDs may include tags like ":latest" or ":7b" which are stripped before matching.
    static func forModel(_ modelId: String) -> String? {
        // Strip tag (e.g. "llama3.2:1b" → "llama3.2")
        let baseId = modelId.components(separatedBy: ":").first?.lowercased() ?? modelId.lowercased()
        
        // Try longest prefix match first for specificity
        // (e.g. "llama3.2" should match before "llama3" which should match before "llama")
        let sortedFamilies = families.sorted { $0.prefix.count > $1.prefix.count }
        
        for family in sortedFamilies {
            if baseId.hasPrefix(family.prefix) {
                // Ensure we're matching at a word boundary:
                // "llama3.2" matches "llama3" but "llama321" should not
                let remainder = String(baseId.dropFirst(family.prefix.count))
                if remainder.isEmpty || remainder.first?.isNumber == true || remainder.first?.isPunctuation == true {
                    return family.attribution
                }
            }
        }
        
        return nil
    }
}