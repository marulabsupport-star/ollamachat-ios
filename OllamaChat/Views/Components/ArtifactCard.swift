import SwiftUI
import WebKit

// MARK: - Artifact Card (Compact preview)

struct ArtifactCard: View {
    let artifact: Artifact
    var onTap: (() -> Void)? = nil
    
    private var codePreview: String {
        extractCodePreview(from: artifact.rawContent, maxLines: 3)
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: artifact.type.icon)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.accentColor.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text(artifact.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Type badge
                    Text(artifact.type.label)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                
                Divider()
                
                // Code preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(codePreview)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    
                    Text("Tap to preview →")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                }
                .padding(12)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artifact Preview Sheet (Bottom Sheet)

struct ArtifactPreviewSheet: View {
    let artifact: Artifact
    @State private var isFullscreen = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type badge
                HStack {
                    Image(systemName: artifact.type.icon)
                        .font(.caption)
                    Text(artifact.type.label)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // WebView
                WebView(html: artifact.htmlContent)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .navigationTitle(artifact.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFullscreen = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
            }
            .fullScreenCover(isPresented: $isFullscreen) {
                ArtifactFullscreenView(artifact: artifact) {
                    isFullscreen = false
                }
            }
        }
    }
}

// MARK: - Artifact Fullscreen View

struct ArtifactFullscreenView: View {
    let artifact: Artifact
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Image(systemName: artifact.type.icon)
                    .font(.subheadline)
                Text(artifact.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            WebView(html: artifact.htmlContent)
                .ignoresSafeArea()
        }
        .background(Color(.systemBackground))
    }
}