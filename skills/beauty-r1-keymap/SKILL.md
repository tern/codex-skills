---
name: beauty-r1-keymap
description: 在 macOS 使用 Karabiner-Elements 修改 Beauty-R1（DY10）藍牙遙控器按鍵。適用於重新設定 Beauty-R1、控制 Ghostty 中的 Codex CLI，或辨識遙控器的 HID 事件。
---

# Beauty-R1 改鍵

從 [已驗證的 Ghostty 規則](assets/ghostty-codex.json)開始修改。如果換了遙控器、韌體或 Mac，先重新測量事件與裝置識別碼。

## 已驗證的事件

| 實體操作 | EventViewer 事件 | 目前在 Ghostty 的功能 |
| --- | --- | --- |
| 長按上鍵 | `consumer_key_code: volume_increment` | `up_arrow` |
| 長按下鍵 | `consumer_key_code: volume_decrement` | `down_arrow` |
| 短按上、下、左、右或中央愛心 | `pointing_button: button1` | `return_or_enter` |

Karabiner 無法區分上述五種短按。長按上鍵或下鍵會重複發送事件，因此可能移動多個選項。

本次測得的裝置識別碼：vendor ID `1452`、product ID `556`、`is_pointing_device: true`。Ghostty 的 bundle ID 是 `com.mitchellh.ghostty`。

## 修改流程

1. 讀取並備份 `~/.config/karabiner/karabiner.json`。找出已選取的 profile 與 Beauty-R1 規則。保留其他設定。
2. 使用 Karabiner-EventViewer 分別記錄每個實體操作。核對事件是否真的不同。換裝置時，在 Devices 頁重新核對識別碼。
3. 修改 Beauty-R1 規則的 `from`、`to` 與條件。用 `device_if` 限定遙控器；用 `frontmost_application_if` 限定目標程式。啟用該裝置的 **Modify events**；設定檔中的對應裝置須為 `ignore: false`。
4. 對獨立規則檔執行 `karabiner_cli --lint-complex-modifications <rule.json>`。套用後檢查 Karabiner 是否成功重新載入設定。
5. 在新的 Ghostty 分頁執行 `/bin/cat -v` 測試，避免 Enter 誤觸 Codex CLI 的確認提示。上、下鍵應顯示 `^[[A`、`^[[B`。測試 Enter 時，先輸入 `TEST`，再按遙控器；`TEST` 應換行重現。按 Control-C 結束測試。

如果兩個按鍵送出相同事件，先說明無法直接分開設定，再尋找不同的長按或模式。若使用者要還原，回復備份，或只移除 Beauty-R1 規則與裝置覆寫。
