import Foundation

enum Direction: String, CaseIterable, Identifiable {
    case auto = "自動偵測", enToZh = "英 → 中", zhToEn = "中 → 英"
    var id: String { rawValue }
}

enum TranslateError: LocalizedError {
    case noKey, http(Int, String)
    var errorDescription: String? {
        switch self {
        case .noKey: return "請先到設定輸入 Anthropic API Key"
        case .http(let c, let m): return "API 錯誤 \(c)：\(m)"
        }
    }
}

/// 以 Claude 串流翻譯，讓譯文隨著生成即時顯示。
struct ClaudeClient {
    static let notesMarker = "§§NOTES§§"
    var model = "claude-sonnet-5-5"

    func systemPrompt(to target: String) -> String {
        let today = Date().formatted(date: .long, time: .omitted)
        return """
        你是頂尖的英中雙向翻譯員，今天是 \(today)。目標語言：\(target)。
        規則：
        1. 譯文要像母語人士日常真正會說、會寫的話：優先使用當下流行的口語、網路用語與慣用語（例如 Gen Z 俚語、台灣當代用語），不要逐字直譯或書面腔。
        2. 中文一律使用繁體中文（台灣用語）。英文使用自然的美式英文。
        3. 保留原文語氣（正式、輕鬆、幽默、諷刺）、格式、換行與表情符號。單字、片語、長文皆可處理。
        4. 只輸出譯文本身，不要加引號、前言或解釋。
        5. 譯文結束後，若原文含有俚語、新詞、梗、慣用語或有趣詞源，另起一行輸出 \(Self.notesMarker)，之後用繁體中文以條列簡述：詞意、詞源／流行背景、使用語氣、其他常見說法。若單字輸入，也請列出詞性與 1–2 個例句。若沒有值得說明的內容就完全省略此段。
        6. 不確定的新興用法請誠實標註「可能」，不要捏造詞源。
        """
    }

    func stream(_ text: String, to target: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { cont in
            let task = Task {
                do {
                    guard let key = Keychain.get("apiKey"), !key.isEmpty else { throw TranslateError.noKey }
                    var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                    req.httpMethod = "POST"
                    req.setValue(key, forHTTPHeaderField: "x-api-key")
                    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    req.setValue("application/json", forHTTPHeaderField: "content-type")
                    let body: [String: Any] = [
                        "model": model, "max_tokens": 2048, "stream": true,
                        "system": systemPrompt(to: target),
                        "messages": [["role": "user", "content": text]]
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, resp) = try await URLSession.shared.bytes(for: req)
                    if let h = resp as? HTTPURLResponse, h.statusCode != 200 {
                        var msg = ""
                        for try await line in bytes.lines { msg += line }
                        throw TranslateError.http(h.statusCode, String(msg.prefix(200)))
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "),
                              let d = line.dropFirst(6).data(using: .utf8),
                              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                              j["type"] as? String == "content_block_delta",
                              let delta = j["delta"] as? [String: Any],
                              let t = delta["text"] as? String else { continue }
                        cont.yield(t)
                    }
                    cont.finish()
                } catch { cont.finish(throwing: error) }
            }
            cont.onTermination = { _ in task.cancel() }
        }
    }
}
