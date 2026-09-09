import Foundation

struct WaveSpeedChatService {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case http(Int, String)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return String(localized: "chat.error_missing_key")
            case .invalidResponse:
                return String(localized: "chat.error_invalid_response")
            case .http(let code, let body):
                return String(format: String(localized: "chat.error_http"), locale: .current, code, body)
            case .emptyContent:
                return String(localized: "chat.error_empty")
            }
        }
    }

    private struct RequestBody: Encodable {
        let model: String
        let messages: [APIMessage]
        let temperature: Double
        let max_tokens: Int
    }

    struct APIMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ResponseBody: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]?
        let error: APIError?
    }

    private struct APIError: Decodable {
        let message: String?
    }

    func complete(
        systemPrompt: String,
        history: [ChatMessage],
        userText: String
    ) async throws -> String {
        guard WaveSpeedConfig.isConfigured else {
            throw ServiceError.missingAPIKey
        }

        var messages: [APIMessage] = [
            APIMessage(role: "system", content: systemPrompt)
        ]

        let prior = history
            .filter { $0.sender == .user || $0.sender == .ai }
            .suffix(WaveSpeedConfig.maxHistoryMessages)

        for item in prior {
            let role = item.sender == .user ? "user" : "assistant"
            messages.append(APIMessage(role: role, content: item.text))
        }

        if prior.last?.sender != .user || prior.last?.text != userText {
            messages.append(APIMessage(role: "user", content: userText))
        }

        var request = URLRequest(url: WaveSpeedConfig.baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(WaveSpeedConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let body = RequestBody(
            model: WaveSpeedConfig.model,
            messages: messages,
            temperature: WaveSpeedConfig.temperature,
            max_tokens: WaveSpeedConfig.maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data)
        if !(200...299).contains(http.statusCode) {
            let message = decoded?.error?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw ServiceError.http(http.statusCode, message)
        }

        let content = decoded?.choices?.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let content, !content.isEmpty else {
            throw ServiceError.emptyContent
        }
        return content
    }
}
