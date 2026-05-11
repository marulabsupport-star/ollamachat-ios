import Foundation
import os

/// HTTP client for Ollama API with dual connection (cloud/local) support.
actor ApiClient {
    
    private let logger = Logger(subsystem: "com.openclaw.ollamachat", category: "network")
    
    private let connectionConfig: ConnectionConfig
    private let settingsRepo: SettingsRepository
    
    private let session: URLSession
    
    init(connectionConfig: ConnectionConfig, settingsRepo: SettingsRepository = .shared) {
        self.connectionConfig = connectionConfig
        self.settingsRepo = settingsRepo
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func checkLocalServerHealth() async -> Bool {
        guard let url = connectionConfig.resolvedLocalURL?.appendingPathComponent("api/tags") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.httpMethod = "GET"
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            logger.debug("Local server health check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchLocalModels() async throws -> [OllamaModelInfo] {
        guard let url = connectionConfig.resolvedLocalURL?.appendingPathComponent("api/tags") else {
            throw OllamaError.invalidURL(url: connectionConfig.localServerURL)
        }
        
        let request = buildRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return tagsResponse.models
    }
    
    func streamChat(request: OllamaChatRequest) -> AsyncThrowingStream<StreamEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream<StreamEvent, Error>.makeStream()
        
        Task { [weak self] in
            guard let self = self else {
                continuation.finish()
                return
            }
            
            do {
                let url = self.baseURL.appendingPathComponent("api/chat")
                var req = self.buildRequest(url: url, method: "POST")
                req.httpBody = try JSONEncoder().encode(request)
                
                let (bytes, response) = try await self.session.bytes(for: req)
                try self.validateResponse(response)
                
                let parser = StreamParser()
                
                for try await line in bytes.lines {
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }
                    
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { continue }
                    
                    guard let lineData = trimmed.data(using: .utf8),
                          let streamLine = try? JSONDecoder().decode(OllamaStreamLine.self, from: lineData) else {
                        continue
                    }
                    
                    let content = streamLine.message?.content ?? ""
                    let events = parser.feed(content)
                    for event in events {
                        continuation.yield(event)
                    }
                    
                    if streamLine.done == true {
                        let finalEvents = parser.flush()
                        for event in finalEvents {
                            continuation.yield(event)
                        }
                        continuation.yield(.complete)
                        continuation.finish()
                        return
                    }
                }
                
                let finalEvents = parser.flush()
                for event in finalEvents {
                    continuation.yield(event)
                }
                continuation.yield(.complete)
                continuation.finish()
                
            } catch is CancellationError {
                continuation.yield(.streamCancelled)
                continuation.finish()
            } catch {
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
            }
        }
        
        return stream
    }
    
    nonisolated private var baseURL: URL {
        connectionConfig.activeBaseURL
    }
    
    nonisolated private func buildRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if connectionConfig.activeMode == "cloud",
           let apiKey = settingsRepo.ollamaAPIKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    nonisolated private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.unexpected("Invalid response type")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw OllamaError.apiKeyInvalid
        case 429:
            throw OllamaError.rateLimited
        case 404:
            throw OllamaError.serverUnreachable(url: httpResponse.url?.absoluteString ?? "unknown")
        default:
            throw OllamaError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
    }
}