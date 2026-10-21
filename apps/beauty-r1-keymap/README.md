# Beauty-R1 按鍵設定

這是 macOS 原生介面。你可以選擇 Beauty-R1 三組可辨識操作的功能，再套用到 Karabiner-Elements。

- 長按上鍵：音量增加事件
- 長按下鍵：音量減少事件
- 所有短按：同一個 `button1` 事件

上、下、左、右與中央愛心的短按無法分別設定，因為這台遙控器送出的事件相同。功能選單包含方向鍵、Enter、Esc、Yes（`y` + Enter）、No（`n` + Enter），以及自訂 Karabiner `key_code` 與修飾鍵。

「套用範圍」可選 Ghostty、ChatGPT／Codex Desktop、兩者或自訂 App。選「兩者」時，這些 App 位於前景時都會使用相同的按鍵設定。其他 App 保留遙控器原本功能。此 Mac 的 `/Applications/ChatGPT.app` bundle ID 是 `com.openai.codex`；程式也支援 `com.openai.chat`。Ghostty 的 bundle ID 是 `com.mitchellh.ghostty`。

## 使用

1. 執行下方建置指令。開啟產生的 `dist/Beauty-R1 Keymap.app`。
2. 選擇套用範圍。
3. 選擇每組操作的功能。按「套用設定」。
4. 如選 Ghostty，在新的 Ghostty 分頁執行 `/bin/cat -v`，確認方向鍵或 Enter 的輸出。按 Control-C 結束測試。

套用前，程式會使用 Karabiner CLI 檢查規則，並將完整設定檔備份到 `~/Library/Application Support/BeautyR1Keymap/Backups/`。介面的「還原上次備份」可回復最近一次套用前的設定。程式只修改目前 profile 中的 Beauty-R1 規則與該裝置的 `Modify events` 選項。

## 從原始碼建置

需要 Xcode 與 Karabiner-Elements。執行：

```sh
swift test --disable-sandbox
./scripts/build-app.sh
```

產物位於 `dist/Beauty-R1 Keymap.app`。建置腳本使用本機臨時簽章；這個 App 並未經 Apple 公證。
