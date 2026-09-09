import Foundation

enum WaveSpeedConfig {
    /// OpenAI-compatible LLM: https://wavespeed.ai/docs/llm-service-quick-start
    /// Models: https://wavespeed.ai/llm
    static let model = "deepseek/deepseek-v4-flash"

    static let baseURL = URL(string: "https://llm.wavespeed.ai/v1/chat/completions")!

    /// Info.plist → WAVESPEED_API_KEY
    static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "WAVESPEED_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR_WAVESPEED_API_KEY"
    }

    static let maxHistoryMessages = 16
    static let temperature = 0.85
    static let maxTokens = 280
}
