import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("保存先パス").font(.caption).foregroundColor(.secondary)
                    HStack {
                        TextField("保存先パス", text: $appState.destinationPath)
                            .textFieldStyle(.roundedBorder)
                        Button("選択...") {
                            appState.selectDestination()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("イベント名").font(.caption).foregroundColor(.secondary)
                    TextField("イベント名", text: $appState.eventName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("選択中のSDカード").font(.caption).foregroundColor(.secondary)
                    HStack {
                        TextField("SDカード", text: .constant(appState.selectedSdPath))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        Button("SDカード選択") {
                            appState.selectSDCard()
                        }
                        .disabled(appState.isProcessing)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task { await appState.startProcessing() }
                } label: {
                    Text("処理開始")
                        .frame(width: 80)
                }
                .disabled(appState.isProcessing)

                Toggle("ログイン時に自動起動", isOn: $appState.autoStart)
                    .toggleStyle(.checkbox)

                Toggle("起動時はバックグラウンド（メニューバーのみ）", isOn: $appState.startInBackground)
                    .toggleStyle(.checkbox)
            }

            HStack {
                Text(appState.countLabel)
                    .font(.headline)
                Spacer()
                Text(appState.progressLabel)
                    .foregroundColor(.secondary)
            }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(appState.logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)
                        .id("logBottom")
                }
                .frame(maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .onChange(of: appState.logText) { _ in
                    withAnimation {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 820, minHeight: 600)
    }
}
