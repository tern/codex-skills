# Codex Skills

這個倉庫收錄可重複使用的 Codex skills，以及部分 skill 搭配的應用程式。每份 skill 的 `SKILL.md` 說明適用情境和操作流程；需要細節時，再閱讀同目錄的 `references/`。

## 收錄項目

| Skill | 用途 |
| --- | --- |
| [utmctl](skills/utmctl/SKILL.md) | 在 macOS 透過 UTM 的 `utmctl` 管理虛擬機、執行來賓系統指令、傳檔、查詢 IP、連接 USB 與管理快照。指令參考以 UTM 5.0.8 核對。 |
| [laravel-docker-stack](skills/laravel-docker-stack/SKILL.md) | 在專案資料夾建立 Laravel 或 PHP 的 Docker 開發環境，包含 Nginx、PHP-FPM、MySQL 與 phpMyAdmin。 |
| [beauty-r1-keymap](skills/beauty-r1-keymap/SKILL.md) | 在 macOS 設定 Beauty-R1 藍牙五鍵裝置，操作 Ghostty 中的 Codex CLI 或 ChatGPT／Codex 桌面版。 |

[`apps/beauty-r1-keymap`](apps/beauty-r1-keymap/) 是 Beauty-R1 skill 搭配的 macOS 應用程式原始碼。

## 使用方式

將需要的整個 skill 資料夾放到 `~/.codex/skills/`，保留其中的 `references/`、`assets/` 等檔案。重新開啟 Codex 對話後，直接描述工作，或明確指定 skill 名稱。例如：

```text
使用 utmctl skill 列出我的 UTM 虛擬機。
```

各 skill 的前置條件與限制以其 `SKILL.md` 為準。執行會修改虛擬機或專案的操作前，請先確認目標與命令。
