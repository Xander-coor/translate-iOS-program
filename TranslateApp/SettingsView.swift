import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var key = Keychain.get("apiKey") ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Anthropic API Key") {
                    SecureField("sk-ant-...", text: $key)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Section { Text("金鑰只存放在這支手機的鑰匙圈（Keychain）。若要公開上架，建議改走自己的後端代理，不要把金鑰放在 App 內。")
                    .font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("設定")
            .toolbar { Button("完成") { Keychain.set(key.trimmingCharacters(in: .whitespacesAndNewlines), for: "apiKey"); dismiss() } }
        }
    }
}
