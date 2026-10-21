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
            .accessibilityLabel("\(name)\(highlighted ? "，亮起" : "")")
    }
}

private struct RemoteTestDiagram: View {
    let input: RemoteInput?

    private var allShortPressKeys: Bool { input == .shortPress }

    var body: some View {
        VStack(spacing: 7) {
            RemoteTestKey(symbol: "arrowtriangle.up.fill", name: "上鍵", highlighted: input == .longUp || allShortPressKeys)
            HStack(spacing: 7) {
                RemoteTestKey(symbol: "arrowtriangle.left.fill", name: "左鍵", highlighted: allShortPressKeys)
                RemoteTestKey(symbol: "heart.fill", name: "愛心鍵", highlighted: allShortPressKeys)
                RemoteTestKey(symbol: "arrowtriangle.right.fill", name: "右鍵", highlighted: allShortPressKeys)
            }
            RemoteTestKey(symbol: "arrowtriangle.down.fill", name: "下鍵", highlighted: input == .longDown || allShortPressKeys)
            Text(input == .shortPress ? "五鍵共用短按事件" : "長按上／下鍵可分別辨識")
                .font(.caption2.weight(.medium))
                .foregroundStyle(input == nil ? Color.white.opacity(0.65) : Color.cyan)
                .padding(.top, 5)
        }
        .frame(width: 218, height: 236)
        .background(Color(red: 0.12, green: 0.14, blue: 0.18), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: input)
    }
}

struct ContentView: View {
    @StateObject private var remoteMonitor = RemoteMonitor()
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
                        Text("選擇功能、檢查規則，然後套用到 Karabiner。")
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
                MappingRow(
                    title: "所有短按",
                    detail: "上、下、左、右、中央愛心都送出同一個 button1 事件。",
                    symbol: "heart.fill",
                    mapping: $settings.shortPress
                )

                Label("這五個短按無法分別指定功能；介面會一起修改。", systemImage: "info.circle")
                    .font(.callout)

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
                        RemoteTestDiagram(input: remoteMonitor.isRunning ? remoteMonitor.lastInput : nil)
                        VStack(alignment: .leading, spacing: 9) {
                            if let input = remoteMonitor.lastInput, remoteMonitor.isRunning {
                                Label("收到：\(input.title)", systemImage: "checkmark.circle.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.cyan)
                                Text("目前選擇：\(input.mapping(in: settings).preset.title)")
                                    .font(.callout)
                                Text("此處顯示功能預覽；套用設定後才會生效。")
                                    .font(.caption).foregroundStyle(.secondary)
                            } else {
                                Text("按鍵後，對應圖示會亮起。")
                                    .font(.callout.weight(.medium))
                                Text("短按無法區分是哪一鍵，因此五個圖示會一起亮起。")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Text("已收到 \(remoteMonitor.eventCount) 次事件")
                                .font(.caption.monospacedDigit())
                            Text("長按可能重複計數。")
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
                    Button("套用設定") { apply() }
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
        .onAppear(perform: reload)
        .onDisappear { remoteMonitor.stop() }
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
