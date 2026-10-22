import SwiftUI
import BeautyR1Core

private extension ActionPreset {
    var title: String {
        switch self {
        case .original: "保留原始功能"
        case .upArrow: "↑ 向上"
        case .downArrow: "↓ 向下"
        case .leftArrow: "← 向左"
        case .rightArrow: "→ 向右"
        case .enter: "Enter／繼續"
        case .escape: "Esc／返回"
        case .space: "空白鍵"
        case .tab: "Tab"
        case .pageUp: "上一頁"
        case .pageDown: "下一頁"
        case .yesAndEnter: "Yes（y + Enter）"
        case .noAndEnter: "No（n + Enter）"
        case .custom: "自訂按鍵碼…"
        }
    }
}

private struct MappingRow: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var mapping: ActionMapping

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
                Picker("功能", selection: $mapping.preset) {
                    ForEach(ActionPreset.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                if mapping.preset == .custom {
                    TextField("Karabiner key_code，例如 f5、delete_or_backspace", text: $mapping.customKeyCode)
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 14) {
                        Toggle("⌘", isOn: $mapping.command)
                        Toggle("⌃", isOn: $mapping.control)
                        Toggle("⌥", isOn: $mapping.option)
                        Toggle("⇧", isOn: $mapping.shift)
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RemoteTestKey: View {
    let symbol: String
    let name: String
    let highlighted: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(highlighted ? Color.black : Color.white.opacity(0.85))
            .frame(width: 54, height: 54)
            .background(highlighted ? Color.cyan : Color.white.opacity(0.12), in: Circle())
            .overlay(Circle().strokeBorder(highlighted ? Color.white : Color.white.opacity(0.15), lineWidth: highlighted ? 2 : 1))
            .shadow(color: highlighted ? Color.cyan.opacity(0.8) : .clear, radius: highlighted ? 14 : 0)
            .scaleEffect(highlighted ? 1.08 : 1)
            .animation(.easeOut(duration: 0.22), value: highlighted)
            .accessibilityLabel("\(name)\(highlighted ? "，亮起" : "")")
    }
}

private struct RemoteTestDiagram: View {
    let event: RemoteButtonEvent?
    @State private var highlightedButton: RemoteButton?

    var body: some View {
        VStack(spacing: 7) {
            RemoteTestKey(symbol: "arrowtriangle.up.fill", name: "上鍵", highlighted: highlightedButton == .up)
            HStack(spacing: 7) {
                RemoteTestKey(symbol: "arrowtriangle.left.fill", name: "左鍵", highlighted: highlightedButton == .left)
                RemoteTestKey(symbol: "heart.fill", name: "愛心鍵", highlighted: highlightedButton == .center)
                RemoteTestKey(symbol: "arrowtriangle.right.fill", name: "右鍵", highlighted: highlightedButton == .right)
            }
            RemoteTestKey(symbol: "arrowtriangle.down.fill", name: "下鍵", highlighted: highlightedButton == .down)
            Text(event.map { "已辨識：\($0.button.title)" } ?? "請短按任一按鍵")
                .font(.caption2.weight(.medium))
                .foregroundStyle(event == nil ? Color.white.opacity(0.65) : Color.cyan)
                .padding(.top, 5)
        }
        .padding(16)
        .frame(width: 218, height: 236)
        .background(Color(red: 0.12, green: 0.14, blue: 0.18), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .onChange(of: event) { newEvent in highlightedButton = newEvent?.button }
        .task(id: event?.sequence) {
            guard event != nil else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            highlightedButton = nil
        }
    }
}

private struct ShortcutRow: View {
    let button: RemoteButton
    let symbol: String
    @Binding var shortcut: KeyboardShortcut

    var body: some View {
        HStack {
            Label(button.title, systemImage: symbol)
                .frame(maxWidth: .infinity, alignment: .leading)
            ShortcutRecorder(shortcut: $shortcut)
                .frame(width: 150)
        }
    }
}

struct ContentView: View {
    @ObservedObject var remoteMonitor: RemoteMonitor
    @State private var settings = KeymapSettings()
    @State private var status = "正在讀取 Karabiner 設定…"
    @State private var errorMessage: String?
    @State private var hasInstalledRule = false
    @State private var hasBackup = false
    @State private var showRestoreConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Beauty-R1 按鍵設定").font(.largeTitle.bold())
                        Text("設定五鍵短按、測試遙控器，並選擇目標 App。")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("套用範圍").font(.headline)
                    Picker("前景 App", selection: $settings.targetApps) {
                        Text("Ghostty").tag(TargetApps.ghostty)
                        Text("ChatGPT / Codex").tag(TargetApps.codexDesktop)
                        Text("兩者").tag(TargetApps.both)
                        Text("自訂 App").tag(TargetApps.custom)
                    }
                    .pickerStyle(.segmented)
                    if settings.targetApps == .custom {
                        TextField("App bundle ID，例如 com.example.app", text: $settings.bundleID)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("只在所選 App 位於前景時生效；選「兩者」時，Ghostty 與 ChatGPT／Codex Desktop 使用相同按鍵設定。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                MappingRow(
                    title: "長按上鍵",
                    detail: "Beauty-R1 送出音量增加事件；按住時可能重複。",
                    symbol: "arrow.up",
                    mapping: $settings.longUp
                )
                MappingRow(
                    title: "長按下鍵",
                    detail: "Beauty-R1 送出音量減少事件；按住時可能重複。",
                    symbol: "arrow.down",
                    mapping: $settings.longDown
                )
                Text("長按規則需由 Karabiner 執行；五鍵短按對映需先退出 Karabiner。")
                    .font(.caption).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 10) {
                    Text("五鍵短按對映").font(.headline)
                    Text("按右側欄位，再按要對映的鍵盤按鍵。可同時按修飾鍵。")
                        .font(.caption).foregroundStyle(.secondary)
                    ShortcutRow(button: .up, symbol: "arrow.up", shortcut: shortcutBinding(.up))
                    ShortcutRow(button: .down, symbol: "arrow.down", shortcut: shortcutBinding(.down))
                    ShortcutRow(button: .left, symbol: "arrow.left", shortcut: shortcutBinding(.left))
                    ShortcutRow(button: .right, symbol: "arrow.right", shortcut: shortcutBinding(.right))
                    ShortcutRow(button: .center, symbol: "heart.fill", shortcut: shortcutBinding(.center))
                    HStack {
                        Button(remoteMonitor.mappingEnabled ? "停止按鍵對映" : "啟用按鍵對映") {
                            if remoteMonitor.mappingEnabled { remoteMonitor.disableMapping() }
                            else { _ = remoteMonitor.enableMapping() }
                        }
                        Text("對映只在選定的前景 App 生效。此 App 必須保持執行。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !AXIsProcessTrusted() {
                        Link("開啟輔助使用設定", destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            .font(.caption)
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("實體按鍵測試").font(.headline)
                        Spacer()
                        Button(remoteMonitor.isRunning ? "停止測試" : "開始測試") {
                            if remoteMonitor.isRunning {
                                remoteMonitor.stop()
                            } else {
                                remoteMonitor.start()
                            }
                        }
                    }
                    Text(remoteMonitor.status)
                        .font(.caption).foregroundStyle(.secondary)
                    if remoteMonitor.needsInputMonitoring {
                        Link("開啟輸入監控設定", destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
                            .font(.caption)
                    }
                    HStack(alignment: .center, spacing: 18) {
                        RemoteTestDiagram(
                        event: remoteMonitor.isRunning ? remoteMonitor.buttonEvent : nil
                        )
                        VStack(alignment: .leading, spacing: 9) {
                            if let button = remoteMonitor.lastButton, remoteMonitor.isRunning {
                                Label("收到：\(button.title)", systemImage: "checkmark.circle.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.cyan)
                                Text("目前對映：\(remoteMonitor.shortcuts[button].label)")
                                    .font(.callout)
                                Text(remoteMonitor.mappingEnabled ? "已啟用；切換到目標 App 後生效。" : "目前只測試圖示，尚未送出鍵盤事件。")
                                    .font(.caption).foregroundStyle(.secondary)
                            } else {
                                Text("按鍵後，對應圖示會亮起約一秒。")
                                    .font(.callout.weight(.medium))
                        Text("五個短按會分別辨識，只有對應圖示亮起。")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                    Text("已辨識 \(remoteMonitor.buttonCount) 次短按")
                                .font(.caption.monospacedDigit())
                            Text(RemoteButton.allCases.map { "\($0.title) \(remoteMonitor.buttonCounts[$0, default: 0])" }.joined(separator: " · "))
                                .font(.caption.monospacedDigit())
                            Text("同一鍵的連續重複訊號會合併。")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(remoteMonitor.usesSystemEvents
                         ? "此處監聽系統事件。其他滑鼠的左鍵也可能被計入；不會修改 Karabiner 設定。"
                         : remoteMonitor.usesVirtualDevice
                         ? "此處監聽 Karabiner 的虛擬裝置；其他經此裝置輸出的按鍵也可能被計入。"
                         : "這裡讀取 Beauty-R1 的原始事件，不會修改 Karabiner 設定。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button("套用 Karabiner 長按規則") { apply() }
                        .buttonStyle(.borderedProminent)
                    Button("重新讀取") { reload() }
                    Button("還原上次備份") { showRestoreConfirmation = true }
                        .disabled(!hasBackup)
                    Spacer()
                    Text(hasInstalledRule ? "已載入現有規則" : "尚未套用規則")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            .padding(26)
            .frame(maxWidth: 760)
        }
        .frame(width: 780)
        .frame(minHeight: 710)
        .onAppear {
            reload()
            if !remoteMonitor.isRunning { remoteMonitor.start() }
        }
        .onChange(of: settings) { newSettings in remoteMonitor.configureTarget(newSettings) }
        .alert("設定失敗", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "未知錯誤")
        }
        .confirmationDialog("還原上次套用前的 Karabiner 設定？", isPresented: $showRestoreConfirmation) {
            Button("還原備份") { restore() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("這會還原整份 Karabiner 設定檔。程式會先備份目前版本。")
        }
    }

    private func shortcutBinding(_ button: RemoteButton) -> Binding<KeyboardShortcut> {
        Binding(
            get: { remoteMonitor.shortcuts[button] },
            set: { remoteMonitor.setShortcut($0, for: button) }
        )
    }

    private func reload() {
        do {
            let (loaded, installed) = try KarabinerStore.load()
            settings = loaded
            hasInstalledRule = installed
            hasBackup = KarabinerStore.latestBackup() != nil
            status = installed ? "已讀取目前的 Beauty-R1 規則。" : "使用預設值；套用後才會修改 Karabiner。"
        } catch {
            errorMessage = error.localizedDescription
            status = "無法讀取 Karabiner 設定。"
        }
    }

    private func apply() {
        do {
            let backup = try KarabinerStore.apply(settings)
            reload()
            status = "已套用。套用前備份：\(backup.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() {
        do {
            let restored = try KarabinerStore.restoreLatest()
            reload()
            status = "已還原：\(restored.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
