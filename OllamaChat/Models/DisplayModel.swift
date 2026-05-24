import Foundation

/// UI model for the model picker dropdown
struct DisplayModel: Identifiable, Hashable {
    let id: String          // model identifier e.g. "llama3.2" or "gemma2:9b"
    let displayName: String // human-readable name
    let sizeLabel: String?  // e.g. "4.7 GB" — nil for cloud models
    let connectionMode: String  // "cloud" | "local"
    let isCloud: Bool
    var supportsVision: Bool  // set from /api/show capabilities or families heuristic
    
    /// Brand attribution for known model families (e.g. "by Meta", "by Google")
    var attribution: String? {
        ModelAttribution.forModel(id)
    }
    
    /// Display name with attribution when available (e.g. "Llama 3.2 (by Meta)")
    var attributedDisplayName: String {
        if let attr = attribution {
            return "\(displayName) (\(attr))"
        }
        return displayName
    }
    
    var subtitle: String {
        if let size = sizeLabel {
            return isCloud ? "Cloud • \(size)" : "Local • \(size)"
        }
        return isCloud ? "Cloud" : "Local"
    }
    
    /// Return a copy with updated vision support flag
    func withVisionSupport(_ supports: Bool) -> DisplayModel {
        DisplayModel(
            id: id,
            displayName: displayName,
            sizeLabel: sizeLabel,
            connectionMode: connectionMode,
            isCloud: isCloud,
            supportsVision: supports
        )
    }
    
    // MARK: - Hashable (exclude supportsVision from hashing)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DisplayModel, rhs: DisplayModel) -> Bool {
        lhs.id == rhs.id
    }
}