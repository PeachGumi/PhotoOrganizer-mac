# PhotoOrganizer-mac

Mac向けの写真/動画整理アプリです。  
SDカードを検知してメディアをスキャンし、指定保存先へ以下の形式で自動整理します。

```text
[保存先]/[YYYY]/[YYYY-MM-DD]_[イベント名]/[RAW|JPG|MP4]/
```

## 機能

- **SDカード自動検知**: 挿入時に自動でウィンドウを表示
- **メニューバー常駐**: 普段はバックグラウンドで動作
- **メディア自動分類**: RAW / JPG / MP4 フォルダへ振り分け
- **日付ベース整理**: EXIF情報から日付を取得して年/日付フォルダを作成
- **重複スキップ**: 同名ファイルでサイズ・更新日時が一致する場合はスキップ
- **整合性チェック**: コピー後にファイルの整合性を検証
- **失敗ファイル自動再試行**: 失敗したファイルは1回だけ再試行
- **ログイン時自動起動**: 設定でON/OFF可能

## 必要条件

- macOS 13.0 (Ventura) 以降
- Xcode 15.0 以降（`swift build` コマンドに必要）

Apple ID は不要です。依存パッケージ・コード署名もなしで、Xcode をインストールして `make build` するだけで誰でもビルドできます。

## ビルド

```bash
make build
```

## インストール

```bash
make install
```

`/Applications/PhotoOrganizer-mac.app` にインストールされます。

## アンインストール

```bash
make uninstall
```

## 使い方

1. `/Applications/PhotoOrganizer-mac.app` をダブルクリックで起動
2. メニューバーにアイコンが表示される
3. SDカードを接続すると自動でウィンドウが開く
4. イベント名を入力して「処理開始」をクリック
5. 完了ログを確認

## 設定ファイル

`config.json` でRAW拡張子をカスタマイズできます。

### 設定ファイルの場所

**優先順位:**

1. `~/Library/Application Support/PhotoOrganizer-mac/config.json` （ユーザー設定・推奨）
2. `/Applications/PhotoOrganizer-mac.app/Contents/Resources/config.json` （デフォルト）

### カスタマイズ方法

```bash
# 設定ディレクトリを作成
mkdir -p ~/Library/Application\ Support/PhotoOrganizer-mac

# 設定ファイルを作成（例）
cat > ~/Library/Application\ Support/PhotoOrganizer-mac/config.json << 'EOF'
{
  "RawExtensions": [".arw", ".cr2", ".cr3", ".nef", ".dng", ".raf", ".rw2", ".orf", ".pef"]
}
EOF
```

### 設定例

```json
{
  "RawExtensions": [".arw", ".cr2", ".cr3", ".nef", ".dng", ".raf", ".rw2", ".orf", ".pef"]
}
```

- 先頭 `.` あり/なし両対応（内部で正規化）
- 変更後はアプリ再起動で反映

## 状態保存場所

```text
~/Library/Application Support/PhotoOrganizer-mac/state.json
```

以下の状態が保存されます：
- 保存先パス
- 選択中のSDパス
- ログイン時自動起動設定
- 起動時バックグラウンド設定

## 開発

```bash
# ビルド＆即実行（既存プロセスは自動停止）
make dev

# テスト実行
make test

# Xcodeで開く
open Package.swift
```

## テスト

```bash
swift test
# または
make test
```

### テスト構成

| テストファイル | 内容 |
|--------------|------|
| `MediaScannerTests` | ファイル列挙、拡張子判定、カウント |
| `MediaProcessorTests` | コピー、重複判定、整合性チェック、サニタイズ |
| `ConfigManagerTests` | 設定読み込み、拡張子正規化 |
| `ExifReaderTests` | EXIF日付取得、フォールバック |
| `StateManagerTests` | 状態保存・読み込み |
| `IntegrationTests` | End-to-Endファイル処理 |

## ディレクトリ構造

```
PhotoOrganizer-mac/
├── Package.swift              # Swift Package設定
├── Makefile                   # ビルドスクリプト
├── config.json                # RAW拡張子設定
├── Resources/
│   └── Info.plist             # アプリ情報
└── Sources/PhotoOrganizer/
    ├── PhotoOrganizerApp.swift    # エントリポイント
    ├── ContentView.swift          # UI
    ├── AppState.swift             # 状態管理
    ├── SDCardDetector.swift       # SDカード検知
    ├── MediaScanner.swift         # ファイルスキャン
    ├── MediaProcessor.swift       # コピー処理
    ├── ExifReader.swift           # EXIF日付取得
    ├── ConfigManager.swift        # 設定読み込み
    ├── StateManager.swift         # 状態保存
    ├── LoginItemManager.swift     # ログインアイテム管理
    └── Models.swift               # データモデル
```

## 対応形式

- **RAW**: .arw, .cr2, .cr3, .nef, .dng, .raf, .rw2, .orf, .pef（設定で変更可）
- **JPG**: .jpg, .jpeg
- **動画**: .mp4, .mov

## ライセンス

MIT License
