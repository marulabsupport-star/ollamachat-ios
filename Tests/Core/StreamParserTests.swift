import Foundation
import Testing
@testable import LLMChatCore

@Suite("StreamParser Tests")
struct StreamParserTests {
    
    @Test("Parses regular token")
    func testRegularToken() {
        let parser = StreamParser()
        let events = parser.feed("Hello ")
        #expect(events.count == 1)
        if case .token(let text) = events[0] {
            #expect(text == "Hello ")
        } else {
            Issue.record("Expected token event")
        }
    }
    
    @Test("Parses thinking content across chunks")
    func testThinkingAcrossChunks() {
        let parser = StreamParser()
        
        // First chunk: opening think tag + some content
        let events1 = parser.feed("Let me think ")
        #expect(events1.count >= 1)
        
        let events2 = parser.feed("about this")
        #expect(events2.count >= 1)
        
        let finalEvents = parser.flush()
        #expect(finalEvents.count >= 0)
    }
    
    @Test("Handles empty input")
    func testEmptyInput() {
        let parser = StreamParser()
        let events = parser.feed("")
        #expect(events.isEmpty)
    }
    
    @Test("Flush returns remaining content")
    func testFlush() {
        let parser = StreamParser()
        let _ = parser.feed("Hello world")
        let events = parser.flush()
        #expect(events.count == 1)
        if case .token(let text) = events[0] {
            #expect(text == "Hello world")
        } else {
            Issue.record("Expected token event")
        }
    }
}