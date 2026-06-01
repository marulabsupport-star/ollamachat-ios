import Foundation

// MARK: - Artifact Types

enum ArtifactType: String {
    case html
    case mermaid
    case svg
    
    var icon: String {
        switch self {
        case .html: return "bolt.fill"
        case .mermaid: return "chart.bar.doc"
        case .svg: return "paintbrush"
        }
    }
    
    var label: String {
        switch self {
        case .html: return "HTML"
        case .mermaid: return "Mermaid"
        case .svg: return "SVG"
        }
    }
}

// MARK: - Artifact Data

struct Artifact: Identifiable {
    let id = UUID()
    let title: String
    let htmlContent: String
    let rawContent: String
    let type: ArtifactType
}

// MARK: - Artifact Extraction

/// Extract HTML artifact from AI message content.
/// Supports: ```artifact, ```html, ```mermaid, ```svg code blocks.
func extractArtifact(from content: String) -> Artifact? {
    // Pattern 1: ```artifact ... ```
    if let match = ArtifactHelper.matchCodeBlock(content, language: "artifact") {
        let html = match.code.trimmingCharacters(in: .whitespacesAndNewlines)
        if !html.isEmpty {
            let title = ArtifactHelper.extractTitle(from: html) ?? "Artifact"
            return Artifact(
                title: title,
                htmlContent: ArtifactHelper.wrapInFullHtml(html),
                rawContent: match.code,
                type: .html
            )
        }
    }
    
    // Pattern 2: ```html ... ``` (any HTML with style or content)
    if let match = ArtifactHelper.matchCodeBlock(content, language: "html") {
        let html = match.code.trimmingCharacters(in: .whitespacesAndNewlines)
        if !html.isEmpty {
            let title = ArtifactHelper.extractTitle(from: html) ?? "HTML Preview"
            return Artifact(
                title: title,
                htmlContent: ArtifactHelper.wrapInFullHtml(html),
                rawContent: match.code,
                type: .html
            )
        }
    }
    
    // Pattern 2.5: ```css ... ``` with preceding ```html
    // When AI outputs HTML and CSS as separate blocks, merge them
    if let cssMatch = ArtifactHelper.matchCodeBlock(content, language: "css") {
        let css = cssMatch.code.trimmingCharacters(in: .whitespacesAndNewlines)
        if !css.isEmpty {
            // Try to find an HTML block to merge with
            if let htmlMatch = ArtifactHelper.matchCodeBlock(content, language: "html") {
                let html = htmlMatch.code.trimmingCharacters(in: .whitespacesAndNewlines)
                if !html.isEmpty {
                    let merged = ArtifactHelper.injectCssIntoHtml(css, html: html)
                    let title = ArtifactHelper.extractTitle(from: html) ?? "Web Page"
                    return Artifact(
                        title: title,
                        htmlContent: ArtifactHelper.wrapInFullHtml(merged),
                        rawContent: html + "\n\n/* CSS */\n" + css,
                        type: .html
                    )
                }
            }
            // CSS only — wrap in basic HTML
            let title = "CSS Preview"
            let html = ArtifactHelper.wrapCssAsHtml(css)
            return Artifact(
                title: title,
                htmlContent: html,
                rawContent: css,
                type: .html
            )
        }
    }
    
    // Pattern 3: ```mermaid ... ```
    if let match = ArtifactHelper.matchCodeBlock(content, language: "mermaid") {
        let mermaidCode = match.code.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mermaidCode.isEmpty {
            return Artifact(
                title: "Mermaid Diagram",
                htmlContent: ArtifactHelper.wrapMermaidHtml(mermaidCode),
                rawContent: match.code,
                type: .mermaid
            )
        }
    }
    
    // Pattern 4: ```svg ... ```
    if let match = ArtifactHelper.matchCodeBlock(content, language: "svg") {
        let svgCode = match.code.trimmingCharacters(in: .whitespacesAndNewlines)
        if !svgCode.isEmpty {
            let title = ArtifactHelper.extractTitle(from: svgCode) ?? "SVG Graphic"
            return Artifact(
                title: title,
                htmlContent: ArtifactHelper.wrapSvgHtml(svgCode),
                rawContent: match.code,
                type: .svg
            )
        }
    }
    
    return nil
}

/// Strip artifact blocks from content for clean message text display.
func stripArtifactBlocks(from content: String) -> String {
    var result = content
    for lang in ["artifact", "html", "css", "mermaid", "svg"] {
        let pattern = "```\(lang)\n[\\s\\S]*?```"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
    }
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Extract first few lines of code preview from artifact content.
func extractCodePreview(from content: String, maxLines: Int = 3) -> String {
    for lang in ["artifact", "html", "css", "mermaid", "svg"] {
        if let match = ArtifactHelper.matchCodeBlock(content, language: lang) {
            let lines = match.code
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return Array(lines.prefix(maxLines)).joined(separator: "\n")
        }
    }
    return content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .prefix(maxLines)
        .joined(separator: "\n")
}

// MARK: - Artifact Helper (namespace for internal functions)

struct ArtifactHelper {
    
    static func matchCodeBlock(_ content: String, language: String) -> CodeBlock? {
        let pattern = "```\(language)\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(content.startIndex..., in: content)
        guard let match = regex.firstMatch(in: content, range: range),
              let codeRange = Range(match.range(at: 1), in: content),
              let fullRange = Range(match.range, in: content) else { return nil }
        return CodeBlock(language: language, code: String(content[codeRange]), range: fullRange)
    }
    
    static func isInteractiveHtml(_ html: String) -> Bool {
        html.contains("<script") ||
        html.contains("onclick") ||
        html.contains("oninput") ||
        html.contains("addEventListener") ||
        html.contains("<button") ||
        html.contains("<form") ||
        html.contains("<input") ||
        html.contains("function") ||
        html.contains("const ") ||
        html.contains("let ") ||
        html.contains("var ")
    }
    
    static func extractTitle(from html: String) -> String? {
        let pattern = "<title>(.*?)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let titleRange = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[titleRange]).trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - HTML Wrapping
    
    static func wrapInFullHtml(_ html: String) -> String {
        if html.contains("<html") || html.contains("<!DOCTYPE") {
            return enhanceHtmlContent(html)
        }
        let wrapped = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
            "<style>",
            "* { box-sizing: border-box; margin: 0; padding: 0; }",
            "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 16px; background: #0B1120; color: #E2E8F0; }",
            "input, button, select { font-size: 16px; padding: 8px 12px; border-radius: 8px; border: 1px solid #334155; background: #1E293B; color: #E2E8F0; }",
            "button { background: #3B82F6; color: white; border: none; cursor: pointer; padding: 8px 16px; }",
            "button:active { background: #2563EB; }",
            "</style>",
            "</head>",
            "<body>",
            html,
            "</body>",
            "</html>"
        ].joined(separator: "\n")
        return enhanceHtmlContent(wrapped)
    }
    
    static func wrapMermaidHtml(_ mermaidCode: String) -> String {
        let parts = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
            "<script src=\"https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js\"></script>",
            "<style>",
            "* { box-sizing: border-box; margin: 0; padding: 0; }",
            "body { font-family: -apple-system, sans-serif; padding: 16px; background: #0B1120; color: #E2E8F0; display: flex; justify-content: center; align-items: center; min-height: 100vh; }",
            ".mermaid { max-width: 100%; overflow-x: auto; }",
            ".mermaid svg { max-width: 100%; height: auto; }",
            "</style>",
            "<script>",
            "mermaid.initialize({ startOnLoad: true, theme: 'dark', themeVariables: { primaryColor: '#3B82F6', primaryTextColor: '#E2E8F0', primaryBorderColor: '#334155', lineColor: '#64748B', secondaryColor: '#1E293B', tertiaryColor: '#0F172A' } });",
            "</script>",
            "</head>",
            "<body>",
            "<pre class=\"mermaid\">",
            mermaidCode,
            "</pre>",
            "</body>",
            "</html>"
        ]
        return parts.joined(separator: "\n")
    }
    
    static func wrapSvgHtml(_ svgCode: String) -> String {
        let parts = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
            "<style>",
            "* { box-sizing: border-box; margin: 0; padding: 0; }",
            "body { font-family: -apple-system, sans-serif; padding: 16px; background: #0B1120; color: #E2E8F0; display: flex; justify-content: center; align-items: center; min-height: 100vh; }",
            "svg { max-width: 100%; height: auto; }",
            "</style>",
            "</head>",
            "<body>",
            svgCode,
            "</body>",
            "</html>"
        ]
        return parts.joined(separator: "\n")
    }
    
    /// Inject CSS into HTML. If HTML has <style>, append to it. If not, add <style> in <head>.
    static func injectCssIntoHtml(_ css: String, html: String) -> String {
        let styleBlock = "<style>\n" + css + "\n</style>"
        // If HTML already has <style>, append CSS before the closing </style>
        if let closingStyleRange = html.range(of: "</style>", options: .caseInsensitive) {
            return html.replacingCharacters(in: closingStyleRange, with: css + "\n</style>")
        }
        // If HTML has <head>, inject <style> before </head>
        if let closingHeadRange = html.range(of: "</head>", options: .caseInsensitive) {
            return html.replacingCharacters(in: closingHeadRange, with: styleBlock + "\n</head>")
        }
        // If HTML has <body>, inject before <body>
        if let bodyRange = html.range(of: "<body", options: .caseInsensitive) {
            return html.replacingCharacters(in: bodyRange, with: styleBlock + "\n<body")
        }
        // No head/body — just prepend
        return styleBlock + "\n" + html
    }
    
    /// Wrap CSS-only content in a basic HTML page for preview.
    static func wrapCssAsHtml(_ css: String) -> String {
        let parts = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
            "<style>",
            "* { box-sizing: border-box; margin: 0; padding: 0; }",
            "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 16px; background: #0B1120; color: #E2E8F0; }",
            css,
            "</style>",
            "</head>",
            "<body>",
            "<div class=\"preview\">CSS Preview — this stylesheet is active on this page.</div>",
            "</body>",
            "</html>"
        ]
        return parts.joined(separator: "\n")
    }
    
    static func enhanceHtmlContent(_ html: String) -> String {
        var enhanced = html
        
        // If HTML contains <pre class="mermaid"> but no mermaid script, inject it
        if html.contains("class=\"mermaid\"") || html.contains("class='mermaid'") {
            if !html.contains("mermaid.min.js") && !html.contains("mermaid@") {
                let mermaidScript = "<script src=\"https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js\"></script>\n<script>mermaid.initialize({ startOnLoad: true, theme: 'dark', themeVariables: { primaryColor: '#3B82F6', primaryTextColor: '#E2E8F0', primaryBorderColor: '#334155', lineColor: '#64748B', secondaryColor: '#1E293B', tertiaryColor: '#0F172A' } });</script>"
                if enhanced.contains("</head>") {
                    enhanced = enhanced.replacingOccurrences(of: "</head>", with: "\(mermaidScript)\n</head>")
                } else if enhanced.contains("<head>") {
                    enhanced = enhanced.replacingOccurrences(of: "<head>", with: "<head>\n\(mermaidScript)")
                } else {
                    enhanced = "\(mermaidScript)\n\(enhanced)"
                }
            }
        }
        
        return enhanced
    }
}