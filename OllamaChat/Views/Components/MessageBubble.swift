import SwiftUI
import WebKit

// MARK: - Code Block Detection

struct CodeBlock {
    let language: String
    let code: String
    let range: Range<String.Index>
}

func extractCodeBlocks(_ content: String) -> [CodeBlock] {
    var blocks: [CodeBlock] = []
    let pattern = #"```(\w*)\n([\s\S]*?)```"#
    
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return blocks }
    let range = NSRange(content.startIndex..., in: content)
    
    for match in regex.matches(in: content, range: range) {
        let langRange = Range(match.range(at: 1), in: content) ?? content.startIndex..<content.startIndex
        let codeRange = Range(match.range(at: 2), in: content) ?? content.startIndex..<content.startIndex
        let fullRange = Range(match.range, in: content) ?? content.startIndex..<content.startIndex
        
        let language = String(content[langRange]).lowercased()
        let code = String(content[codeRange])
        
        blocks.append(CodeBlock(language: language, code: code, range: fullRange))
    }
    
    return blocks
}

func isRunnableCode(_ block: CodeBlock) -> Bool {
    let lang = block.language
    return lang == "html" || lang == "javascript" || lang == "js" || lang == "" || lang == "css"
        || block.code.contains("<html") || block.code.contains("<!DOCTYPE") || block.code.contains("<div")
}

func wrapForWebView(_ block: CodeBlock) -> String {
    let code = block.code
    
    if code.contains("<!DOCTYPE") || code.contains("<html") {
        return code
    }
    
    if block.language == "javascript" || block.language == "js" {
        return """
        <!DOCTYPE html>
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <style>body{font-family:-apple-system,sans-serif;padding:16px;margin:0}.output{background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:8px;font-family:monospace;white-space:pre-wrap}</style>
        </head><body><div id="output" class="output"></div><script>
        const output=document.getElementById('output');function _print(msg){output.textContent+=msg+'\\n';output.scrollTop=output.scrollHeight}
        console.log=(...a)=>_print(a.map(x=>typeof x==='object'?JSON.stringify(x,null,2):String(x)).join(' '));
        console.error=(...a)=>_print('❌ '+a.join(' '));try{\(code)}catch(e){_print('❌ Error: '+e.message)}</script></body></html>
        """
    }
    
    return """
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
    \(block.language == "css" ? "<style>\(code)</style>" : "")
    </head><body>\(block.language != "css" ? code : "<p>CSS Preview</p>")</body></html>
    """
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let showThinking: Bool
    
    var isUser: Bool { message.role == "user" }
    
    private var codeBlocks: [CodeBlock] {
        guard let content = message.content else { return [] }
        return extractCodeBlocks(content)
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            // Thinking section (collapsible)
            if showThinking, let thinking = message.thinkingContent, !thinking.isEmpty {
                DisclosureGroup {
                    Text(thinking)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                } label: {
                    Label("Reasoning", systemImage: "brain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Main content
            if let content = message.content, !content.isEmpty {
                if isUser {
                    HStack {
                        Spacer(minLength: 0)
                        Text(content)
                            .font(.body)
                            .textSelection(.enabled)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                } else if !codeBlocks.isEmpty {
                    // AI message with code blocks
                    VStack(alignment: .leading, spacing: 4) {
                        CodeBlockRichContent(content: content, codeBlocks: codeBlocks)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    // AI message without code blocks
                    Text(content)
                        .font(.body)
                        .textSelection(.enabled)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            
            // Streaming indicator
            if message.isStreaming {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Thinking...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Rich Content with Code Blocks

struct CodeBlockRichContent: View {
    let content: String
    let codeBlocks: [CodeBlock]
    
    var body: some View {
        let segments = splitIntoSegments()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                if segment.isCode, let block = segment.codeBlock {
                    CodeBlockView(block: block)
                } else if !segment.text.isEmpty {
                    Text(segment.text)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
        }
    }
    
    struct Segment {
        let text: String
        let isCode: Bool
        let codeBlock: CodeBlock?
    }
    
    private func splitIntoSegments() -> [Segment] {
        var segments: [Segment] = []
        var currentIndex = content.startIndex
        
        for block in codeBlocks {
            if currentIndex < block.range.lowerBound {
                let text = String(content[currentIndex..<block.range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    segments.append(Segment(text: text, isCode: false, codeBlock: nil))
                }
            }
            segments.append(Segment(text: block.code, isCode: true, codeBlock: block))
            currentIndex = block.range.upperBound
        }
        
        if currentIndex < content.endIndex {
            let text = String(content[currentIndex..<content.endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                segments.append(Segment(text: text, isCode: false, codeBlock: nil))
            }
        }
        
        return segments
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let block: CodeBlock
    @State private var showPreview = false
    @State private var copied = false
    
    private var runnable: Bool { isRunnableCode(block) }
    private var displayLanguage: String { block.language.isEmpty ? "code" : block.language }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(displayLanguage)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = block.code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if runnable {
                    Button {
                        showPreview = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text("Run")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            
            Divider()
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.code)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(Color(.secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .sheet(isPresented: $showPreview) {
            CodePreviewSheet(block: block)
        }
    }
}

// MARK: - Code Preview Sheet (WebView)

struct CodePreviewSheet: View {
    let block: CodeBlock
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(html: wrapForWebView(block))
                .navigationTitle("Preview")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - WKWebView Wrapper

struct WebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                if url.scheme == "http" || url.scheme == "https" {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}