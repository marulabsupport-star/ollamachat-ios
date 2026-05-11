import Testing
@testable import OllamaChat

@Suite("StreamParser Tests")
struct StreamParserTests {
    
    @Test("Parses regular token")
    func testRegularToken() async throws {
        let parser = StreamParser()
        let events = parser.feed("Hello ")
        #expect(events.count == 1)
        #expect(events[0] == .token("Hello "))
    }
}