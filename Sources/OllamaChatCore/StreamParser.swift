import Foundation
import os

/// State machine for parsing think tags (<tool_call> and \boxed) across chunk boundaries.
/// Unlike simple string search, this handles tags split across multiple streaming tokens.
final class StreamParser {
    
    private let logger = Logger(subsystem: "com.openclaw.ollamachat", category: "streaming")
    
    // Think tag markers
    private let thinkOpen = "<think>"
    private let thinkClose = "</think>"
    
    // State machine
    private var isInsideThink: Bool = false
    private var buffer: String = ""
    
    /// Feed a chunk of text and get parsed events.
    /// The parser accumulates text and emits events when think-tag boundaries are crossed.
    func feed(_ chunk: String) -> [StreamEvent] {
        var events: [StreamEvent] = []
        buffer += chunk
        
        while !buffer.isEmpty {
            if isInsideThink {
                // Look for closing tag
                if let closeRange = buffer.range(of: thinkClose) {
                    // Emit accumulated thinking content
                    let thinkingText = String(buffer[..<closeRange.lowerBound])
                    if !thinkingText.isEmpty {
                        events.append(.thinking(thinkingText))
                    }
                    buffer = String(buffer[closeRange.upperBound...])
                    isInsideThink = false
                } else {
                    // Check for partial closing tag at end of buffer
                    let partialMatch = findPartialMatch(of: thinkClose, in: buffer)
                    if partialMatch > 0 {
                        // Emit content up to the partial match
                        let safeContent = String(buffer.dropLast(partialMatch))
                        if !safeContent.isEmpty {
                            events.append(.thinking(safeContent))
                        }
                        buffer = String(buffer.suffix(partialMatch))
                        break // Wait for more data
                    } else {
                        // No closing tag — emit all as thinking
                        if !buffer.isEmpty {
                            events.append(.thinking(buffer))
                        }
                        buffer = ""
                        break
                    }
                }
            } else {
                // Look for opening tag
                if let openRange = buffer.range(of: thinkOpen) {
                    // Emit content before think tag
                    let beforeThink = String(buffer[..<openRange.lowerBound])
                    if !beforeThink.isEmpty {
                        events.append(.token(beforeThink))
                    }
                    buffer = String(buffer[openRange.upperBound...])
                    isInsideThink = true
                } else {
                    // Check for partial opening tag at end of buffer
                    let partialMatch = findPartialMatch(of: thinkOpen, in: buffer)
                    if partialMatch > 0 {
                        // Emit content up to the partial match
                        let safeContent = String(buffer.dropLast(partialMatch))
                        if !safeContent.isEmpty {
                            events.append(.token(safeContent))
                        }
                        buffer = String(buffer.suffix(partialMatch))
                        break // Wait for more data
                    } else {
                        // No think tag — emit all as regular content
                        if !buffer.isEmpty {
                            events.append(.token(buffer))
                        }
                        buffer = ""
                        break
                    }
                }
            }
        }
        
        return events
    }
    
    /// Flush any remaining buffered content. Call at stream end.
    func flush() -> [StreamEvent] {
        var events: [StreamEvent] = []
        
        if !buffer.isEmpty {
            if isInsideThink {
                events.append(.thinking(buffer))
            } else {
                events.append(.token(buffer))
            }
            buffer = ""
        }
        
        // Reset state
        isInsideThink = false
        
        return events
    }
    
    /// Reset parser state for a new stream
    func reset() {
        buffer = ""
        isInsideThink = false
    }
    
    // MARK: - Partial Tag Detection
    
    /// Check if `buffer` ends with a partial match of `tag`.
    /// Returns the number of characters at the end that could be the start of `tag`.
    /// E.g., buffer="hello<thi", tag="<think>" → returns 4 (the "<thi" suffix)
    private func findPartialMatch(of tag: String, in text: String) -> Int {
        let tagChars = Array(tag)
        let textChars = Array(text)
        
        // Check suffixes of decreasing length
        for length in (1..<tagChars.count).reversed() {
            guard length <= textChars.count else { continue }
            let suffix = String(textChars.suffix(length))
            let tagPrefix = String(tagChars.prefix(length))
            
            if suffix == tagPrefix {
                return length
            }
        }
        
        return 0
    }
}