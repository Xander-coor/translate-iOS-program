import SwiftUI
import AVFoundation

@MainActor
final class TranslatorViewModel: ObservableObject {
    @Published var input = "" { didSet { scheduleTranslate() } }
    @Published var direction: Direction = .auto { didSet { scheduleTranslate() } }
    @Published var output = ""
    @Published var notes = ""
    @Published var isLoading = false
    @Published var error: String?

    private let client = ClaudeClient()
    private var task: Task<Void, Never>?
    private let synth = AVSpeechSynthesizer()

    /// 中日韓字元佔比 > 20% 視為中文。
    static func isChinese(_ s: String) -> Bool {
        let letters = s.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return false }
        let cjk = letters.filter { (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value) }
        return Double(cjk.count) / Double(letters.count) > 0.2
    }

    var targetIsChinese: Bool {
        switch direction {
        case .enToZh: return true
        case .zhToEn: return false
        case .auto: return !Self.isChinese(input)
        }
    }

    func swap() {
        guard !output.isEmpty else { return }
        let o = output
        direction = .auto
        input = o
    }

    func speak(_ text: String, chinese: Bool) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: chinese ? "zh-TW" : "en-US")
        synth.speak(u)
    }

    private func scheduleTranslate() {
        task?.cancel()
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { output = ""; notes = ""; error = nil; isLoading = false; return }
        let toZh = targetIsChinese
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000) // debounce：停止打字 0.6 秒後翻譯
            guard !Task.isCancelled, let self else { return }
            await self.run(text, toChinese: toZh)
        }
    }

    private func run(_ text: String, toChinese: Bool) async {
        isLoading = true; error = nil
        var acc = ""
        do {
            for try await chunk in client.stream(text, to: toChinese ? "繁體中文（台灣）" : "English (US)") {
                acc += chunk
                split(acc, final: false)
            }
            split(acc, final: true)
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled { return }
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// 以標記切開譯文與備註；串流中隱藏尚未完整的標記前綴。
    private func split(_ s: String, final: Bool) {
        let m = ClaudeClient.notesMarker
        if let r = s.range(of: m) {
            output = String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            notes = String(s[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }
        var t = s
        if !final {
            for n in stride(from: m.count - 1, through: 1, by: -1) where t.hasSuffix(String(m.prefix(n))) {
                t.removeLast(n); break
            }
        }
        output = t.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = ""
    }
}
