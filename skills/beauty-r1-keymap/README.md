# Beauty-R1 控制 Ghostty 中的 Codex CLI

這份 Codex skill 保存 Beauty-R1（DY10）在 macOS 上的已驗證按鍵設定，也記錄日後重新測量與修改按鍵的方法。

## 目前功能

| 遙控器操作 | Ghostty 功能 |
| --- | --- |
| 長按上鍵 | 向上選擇 |
| 長按下鍵 | 向下選擇 |
| 短按中央愛心 | Enter |

EventViewer 顯示：上、下、左、右與中央愛心的短按都送出 `button1`。因此 Ghostty 中的這五種短按都會觸發 Enter，無法單獨設定中央愛心。長按上、下鍵則分別送出音量增加、減少事件，而且按住時可能重複送出。

規則只套用到 vendor ID `1452`、product ID `556` 的指標裝置，並且只在 Ghostty（`com.mitchellh.ghostty`）位於前景時生效。公開檔案不含遙控器序號。

## 安裝與修改

1. 安裝 Karabiner-Elements。完成其 Setup 頁要求的權限設定。
2. 連接 Beauty-R1。在 **Karabiner-Elements → Devices** 為該裝置開啟 **Modify events**。
3. 將 [`assets/ghostty-codex.json`](assets/ghostty-codex.json) 複製到 `~/.config/karabiner/assets/complex_modifications/`。在 **Complex Modifications → Add predefined rule** 啟用規則。如果這台 Mac 已有該規則，請修改現有規則，避免重複新增。
4. 在新的 Ghostty 分頁執行 `/bin/cat -v`。長按上、下鍵應顯示 `^[[A`、`^[[B`。輸入 `TEST` 後短按中央愛心；若 Enter 生效，`TEST` 會換行重現。按 Control-C 結束測試。

若要改變功能，請修改 JSON 規則的 `to` 欄位。先執行 `karabiner_cli --lint-complex-modifications`，再更新已啟用的規則。[SKILL.md](SKILL.md) 包含事件測量、安全修改與還原流程。

本次設定已在 Karabiner-Elements 16.3.0 與 Ghostty 實測。其他韌體或裝置版本應重新測量。
