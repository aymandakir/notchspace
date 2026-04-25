import Foundation
import Security

// MARK: - Config

public struct AIConfig {
    public var baseURL: String
    public var model:   String

    public static let `default` = AIConfig(
        baseURL: "https://openrouter.ai/api/v1",
        model:   "anthropic/claude-3-haiku"
    )

    private enum Keys {
        static let baseURL = "ai.config.baseURL"
        static let model   = "ai.config.model"
    }

    public static func load() -> AIConfig {
        let d = UserDefaults.standard
        return AIConfig(
            baseURL: d.string(forKey: Keys.baseURL) ?? AIConfig.default.baseURL,
            model:   d.string(forKey: Keys.model)   ?? AIConfig.default.model
        )
    }

    public func save() {
        let d = UserDefaults.standard
        d.set(baseURL, forKey: Keys.baseURL)
        d.set(model,   forKey: Keys.model)
    }
}

// MARK: - Manager

@MainActor
public final class AIAssistantManager: ObservableObject {

    public static let shared = AIAssistantManager()

    @Published public var isLoading: Bool    = false
    @Published public var response:  String  = ""
    @Published public var error:     String? = nil
    @Published public var config:    AIConfig = .load()

    private var streamTask: Task<Void, Never>?

    private init() {}

    // MARK: - Keychain

    private static let keychainService = "space.notch.ai"
    private static let keychainAccount = "apikey"

    public func saveAPIKey(_ key: String) {
        let data = Data(key.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: Self.keychainAccount,
        ]
        let attrs: [CFString: Any] = [kSecValueData: data]

        if SecItemUpdate(query as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    public var apiKey: String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: Self.keychainAccount,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var ref: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAPIKey() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: Self.keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Send

    public func send(prompt: String) {
        streamTask?.cancel()
        error     = nil
        response  = ""
        isLoading = true

        streamTask = Task { await stream(prompt: prompt) }
    }

    public func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isLoading  = false
    }

    // MARK: - Streaming

    private func stream(prompt: String) async {
        defer { Task { @MainActor in isLoading = false } }

        guard let key = apiKey, !key.isEmpty else {
            error = "No API key configured. Click the model chip to set one."
            return
        }

        guard let url = URL(string: config.baseURL.trimmingCharacters(in: .whitespaces) + "/chat/completions") else {
            error = "Invalid base URL."
            return
        }

        var req           = URLRequest(url: url)
        req.httpMethod    = "POST"
        req.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)",        forHTTPHeaderField: "Authorization")
        req.setValue("NotchSpace/1.0",       forHTTPHeaderField: "HTTP-Referer")

        let body: [String: Any] = [
            "model":  config.model,
            "stream": true,
            "messages": [["role": "user", "content": prompt]],
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (asyncBytes, httpResp) = try await URLSession.shared.bytes(for: req)

            if let http = httpResp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                var raw = ""
                for try await byte in asyncBytes { raw.append(Character(UnicodeScalar(byte))) }
                let msg = extractErrorMessage(from: raw) ?? "HTTP \(http.statusCode)"
                await MainActor.run { error = msg }
                return
            }

            for try await line in asyncBytes.lines {
                if Task.isCancelled { break }
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                guard payload != "[DONE]" else { break }
                if let delta = parseDelta(payload) {
                    await MainActor.run { response += delta }
                }
            }
        } catch is CancellationError {
            // user cancelled — leave response as-is
        } catch {
            let msg = error.localizedDescription
            await MainActor.run { self.error = msg }
        }
    }

    // MARK: - SSE parsing

    /// Extracts `choices[0].delta.content` from an OpenAI SSE chunk JSON string.
    private func parseDelta(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let first   = choices.first,
              let delta   = first["delta"]   as? [String: Any],
              let content = delta["content"] as? String
        else { return nil }
        return content
    }

    private func extractErrorMessage(from raw: String) -> String? {
        guard let data = raw.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let err  = obj["error"] as? [String: Any],
              let msg  = err["message"] as? String
        else { return nil }
        return msg
    }
}
