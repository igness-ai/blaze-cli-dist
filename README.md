# Blaze CLI

Salesforce AI DevOps Agent の CLI 配信チャネル。バイナリと install スクリプトを配布します。
ソースは [igness-ai/blaze-cli](https://github.com/igness-ai/blaze-cli) (Private)。

## インストール

### macOS (production)
```bash
curl -fsSL https://cli.igness.ai/install.sh | bash
```

### Windows (production)
```powershell
irm https://cli.igness.ai/install.ps1 | iex
```

### macOS (staging, 社内向け)
```bash
curl -fsSL https://cli.igness.ai/install-stg.sh | bash
```

### Windows (staging, 社内向け)
```powershell
irm https://cli.igness.ai/install-stg.ps1 | iex
```

## 動作要件

- **macOS**: Apple Silicon または Intel
- **Windows**: Windows 10/11、Windows Terminal 推奨 (旧 conhost ではフォント表示が崩れます)
- **Nerd Font 推奨**: TUI のアイコン表示用 (Cascadia Code PL 等)

## アップデート

インストール済みのバイナリから:
```bash
blaze update            # production
blaze-stg update         # staging
```

---

Copyright (c) 2026 igness, inc. All rights reserved.
