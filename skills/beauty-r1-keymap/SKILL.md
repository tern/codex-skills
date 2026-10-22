---
name: beauty-r1-keymap
description: 在 macOS 設定 Beauty-R1（DY10）藍牙遙控器的五鍵短按，控制 Ghostty 中的 Codex CLI 或 ChatGPT／Codex Desktop；也適用於診斷其 HID 事件與 Karabiner 衝突。
---

# Beauty-R1 改鍵

先使用本機 App：`/Users/tern/Documents/Codex/2026-10-21/8-7/BeautyR1Keymap/dist/Beauty-R1 Keymap.app`。原始碼與使用說明位於 GitHub `tern/codex-skills/apps/beauty-r1-keymap/`。

## 五鍵短按

這台 DY10 的藍牙名稱是 Beauty-R1；實測 vendor ID `1452`、product ID `556`。五個短按都帶有 `button1`，但按下期間的原始滑鼠位移不同。上鍵 Y 約 +122、下鍵 Y 約 −120、左鍵 X 約 +64、右鍵 X 約 −96；愛心鍵沒有明顯位移。按下前可能出現約 ±2047 的定位位移，辨識時應忽略。換裝置、韌體或 Mac 時，重新測量。

App 會獨占實體 HID 裝置，依按下後的位移區分五鍵，並防止遙控器的原始滑鼠點擊送到桌面。測試區會點亮對應圖示。裝置休眠時，第一次短按可能只會喚醒裝置；再按一次確認。按右側的對映欄位，再按實體鍵盤上的目標按鍵，可分別設定五鍵；支援修飾鍵。設定自動儲存。選擇目標 App 後，按「啟用按鍵對映」，保持 App 執行。

Karabiner-Elements 若接管 Beauty-R1，App 只能看到 Karabiner 的虛擬輸出，無法區分五鍵。要使用五鍵模式，先在 Karabiner-Elements Settings 的「Quit, Restart」退出 Karabiner。App 需要 macOS「輸入監控」權限才能讀取事件，送出模擬鍵盤事件另需「輔助使用」權限。建置腳本使用臨時簽章；重建後 macOS 可能要求重新授權。

## 舊版 Karabiner 規則

[已驗證的 Ghostty 規則](assets/ghostty-codex.json)可作為手動修改起點。Karabiner 可將長按上鍵的 `volume_increment` 設為 `up_arrow`，長按下鍵的 `volume_decrement` 設為 `down_arrow`；它目前把五個短按的共同 `button1` 設為 `return_or_enter`。舊版規則只適合把五鍵當作同一個短按，不適合各鍵獨立對映。這台 Mac 的 Ghostty bundle ID 是 `com.mitchellh.ghostty`；ChatGPT／Codex Desktop 是 `com.openai.codex`。

實體輸出檢查請在 Ghostty 執行 `/bin/cat -v`；不要只執行 `cat`，因為本機 `cat` 可能是 `bat` 的別名。測試後按 Control-C。App 的完整建置與使用流程請讀原始碼的 README。
