import Foundation

/// Singleton managing available model lists.
@Observable
final class AvailableModels {
    
    static let shared = AvailableModels()
    
    let cloudModels: [DisplayModel] = [
        DisplayModel(id: "llama3.3:70b", displayName: "Llama 3.3 70B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
        DisplayModel(id: "llama3.1:8b", displayName: "Llama 3.1 8B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
        DisplayModel(id: "gemma2:9b", displayName: "Gemma 2 9B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
        DisplayModel(id: "mistral:7b", displayName: "Mistral 7B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
        DisplayModel(id: "codellama:34b", displayName: "Code Llama 34B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
        DisplayModel(id: "qwen2.5:72b", displayName: "Qwen 2.5 72B", sizeLabel: nil, connectionMode: "cloud", isCloud: true),
    ]
    
    private let cloudModelIds: Set<String> = [
        "llama3.3:70b", "llama3.1:8b", "gemma2:9b", "mistral:7b",
        "codellama:34b", "qwen2.5:72b"
    ]
    
    var localModels: [DisplayModel] = []
    var isLoadingLocal: Bool = false
    var localError: String?
    
    var allModels: [DisplayModel] {
        cloudModels + localModels
    }
    
    func isCloudModel(_ modelId: String) -> Bool {
        cloudModelIds.contains(modelId)
    }
    
    func isLocalModel(_ modelId: String) -> Bool {
        !isCloudModel(modelId)
    }
    
    func filterSignificantLocalModels(_ models: [OllamaModelInfo]) -> [DisplayModel] {
        models
            .filter { model in
                guard let size = model.size, size > 100_000_000 else { return false }
                return true
            }
            .map { model in
                DisplayModel(
                    id: model.name,
                    displayName: model.name.replacingOccurrences(of: ":latest", with: ""),
                    sizeLabel: model.sizeLabel,
                    connectionMode: "local",
                    isCloud: false
                )
            }
    }
}