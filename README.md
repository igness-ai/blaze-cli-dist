# Blaze CLI

Salesforce AI DevOps Agent の CLI 配信チャネル。バイナリと install スクリプトを配布します。
ソースは [igness-ai/blaze-cli](https://github.com/igness-ai/blaze-cli) (Private)。

## インストール

### macOS (Apple Silicon)
```bash
curl -fsSL https://cli.igness.ai/install.sh | bash
```

### Windows
```powershell
irm https://cli.igness.ai/install.ps1 | iex
```

## 動作要件

- **macOS**: Apple Silicon
- **Windows**: Windows 10/11、Windows Terminal 推奨 (旧 conhost ではフォント表示が崩れます)
- **Nerd Font 推奨**: TUI のアイコン表示用 (Cascadia Code PL 等)

## アップデート

インストール済みのバイナリから:
```bash
blaze update
```

---

Copyright (c) 2026 igness, inc. All rights reserved.
