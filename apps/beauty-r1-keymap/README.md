# Beauty-R1 Keymap

macOS App，可將 Beauty-R1（DY10）的上、下、左、右、中央愛心五個短按分別對映為鍵盤按鍵。方向鍵位移達到門檻時，介面會立即點亮對應圖示約一秒；愛心鍵在放開時點亮。程式會合併同一鍵的重複訊號。

Beauty-R1 把五個短按都送成滑鼠左鍵；方向鍵還會在按住期間送出不同的滑鼠位移。本 App 在監聽時獨占實體 HID 裝置，利用按下到放開之間的位移辨識五鍵。獨占期間，原始滑鼠點擊和位移不會送到桌面。Karabiner-Elements 若先接管裝置，App 會無法辨識五鍵。使用五鍵模式前，請在 Karabiner-Elements Settings 的「Quit, Restart」退出 Karabiner。

## 使用五鍵模式

1. 執行 `./scripts/build-app.sh`，打開 `dist/Beauty-R1 Keymap.app`。
2. 在 macOS「隱私權與安全性」授予 App「輸入監控」與「輔助使用」權限。授權後重新啟動 App。
3. 在「套用範圍」選 Ghostty、ChatGPT／Codex Desktop、兩者或自訂 App。
4. 在五個對映欄位逐一點擊並按下要使用的鍵盤按鍵。可同時按 Command、Control、Option 或 Shift。設定會自動儲存。
5. 按「開始測試」。短按遙控器五鍵，確認對應圖示各自亮起。
6. 按「啟用按鍵對映」。讓 App 保持執行，並切換到目標 App。

「停止按鍵對映」只停止送出模擬鍵盤事件。按「停止測試」會關閉 HID 裝置，恢復遙控器原本的滑鼠事件。若不使用遙控器，建議斷開藍牙連線，避免原始點擊影響桌面。

## 舊版 Karabiner 功能

介面仍保留長按上／下鍵的 Karabiner 設定與「套用設定」按鈕。這些功能只有 Karabiner 執行時生效；Karabiner 接管裝置時，五鍵辨識與獨立對映無法同時使用。

## 開發

```sh
swift test --disable-sandbox
./scripts/build-app.sh
```

建置腳本使用本機臨時簽章。每次重建 App 後，macOS 可能撤銷「輸入監控」或「輔助使用」授權；需移除舊項目，再加入重建後的 App。設定的備份由 App 保存於 `~/Library/Application Support/BeautyR1Keymap/Backups/`。
