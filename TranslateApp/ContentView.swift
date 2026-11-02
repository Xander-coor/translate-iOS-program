import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TranslatorViewModel()
    @State private var showSettings = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("方向", selection: $vm.direction) {
                        ForEach(Direction.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    card {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $vm.input).focused($focused).frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                            if vm.input.isEmpty {
                                Text("輸入或貼上英文／中文⋯").foregroundStyle(.tertiary)
                                    .padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                            }
                        }
                        HStack {
                            Button { vm.speak(vm.input, chinese: !vm.targetIsChinese) } label: { Image(systemName: "speaker.wave.2") }
                                .disabled(vm.input.isEmpty)
                            Spacer()
                            if !vm.input.isEmpty { Button { vm.input = "" } label: { Image(systemName: "xmark.circle.fill") } }
                        }.foregroundStyle(.secondary)
                    }

                    card(tint: true) {
                        if let e = vm.error {
                            Text(e).foregroundStyle(.red).font(.callout)
                        } else if vm.output.isEmpty && vm.isLoading {
                            ProgressView()
                        } else {
                            Text(vm.output.isEmpty ? "譯文會即時顯示在這裡" : vm.output)
                                .font(.title3).foregroundStyle(vm.output.isEmpty ? .tertiary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                        }
                        HStack(spacing: 18) {
                            Button { vm.speak(vm.output, chinese: vm.targetIsChinese) } label: { Image(systemName: "speaker.wave.2") }
                            Button { UIPasteboard.general.string = vm.output } label: { Image(systemName: "doc.on.doc") }
                            Button { vm.swap() } label: { Image(systemName: "arrow.up.arrow.down") }
                            Spacer()
                            if vm.isLoading { ProgressView().controlSize(.small) }
                        }.foregroundStyle(.secondary).disabled(vm.output.isEmpty)
                    }

                    if !vm.notes.isEmpty {
                        card {
                            Label("用語與詞源", systemImage: "text.book.closed").font(.headline)
                            Text(.init(vm.notes)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                        }
                    }
                }.padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("即時翻譯")
            .toolbar { Button { showSettings = true } label: { Image(systemName: "gearshape") } }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onAppear { if Keychain.get("apiKey") == nil { showSettings = true } }
        }
    }

    @ViewBuilder
    private func card<C: View>(tint: Bool = false, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding()
            .background(tint ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}
