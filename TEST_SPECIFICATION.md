# PhotoOrganizer テスト仕様書

## テスト結果サマリー

- **総テスト数**: 69
- **実行時間**: 約0.9秒
- **全テストパス済み**

---

## 1. データ安全性テスト (DataSafetyTests)

写真データの安全性を最優先で検証するテスト群です。

### 1.1 ソースファイル保護

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSourceFileNotDeleted | 処理実行後にソースファイルが残っていることを確認 | ソースファイルは削除されず、内容も変更されない |
| testSourceFileNotModified | 処理前後でソースファイルのサイズと更新日時が同じであることを確認 | サイズ・日時ともに変更されない |

### 1.2 関係ないファイル保護

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testUnrelatedFilesNotDeleted | SDカード内のメディア以外（README.txt, config.xml, .thumbnail等）が削除されないことを確認 | メディアファイル以外のファイルは全て残る |
| testDestinationUnrelatedFilesNotDeleted | 保存先ディレクトリに既存のイベントフォルダがある場合、それが削除されないことを確認 | 既存のイベントフォルダ内のファイルは全て保持される |

### 1.3 誤上書き防止

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testDifferentContentNotOverwritten | 同名ファイルで内容が異なる場合の動作を確認 | サイズまたは日時が異なる場合は上書きコピーされる |
| testSameNameDifferentSizeNotSkipped | 同名ファイルでサイズが異なる場合、重複と判定されないことを確認 | 重複スキップされず、正常にコピーされる |

### 1.4 エラー時の安全性

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSourceSafeOnProcessError | 存在しないファイルを含む処理を実行した場合、有効なファイルは処理され、ソースは安全であることを確認 | 失敗したファイルはエラー記録されるが、ソースファイルは削除されない |

### 1.5 整合性チェック

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testIntegrityCheckAfterCopy | コピー後にサイズと更新日時の整合性チェックが実行されることを確認 | コピー元とコピー先でサイズ・日時が一致する |

### 1.6 リトライ動作

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testRetryOnFailure | 失敗したファイルの再試行が正しく動作することを確認 | 再試行後は正常にファイルがコピーされる |

---

## 2. エッジケーステスト (EdgeCaseTests)

通常の使用では稀なケースを検証するテスト群です。

### 2.1 存在しないファイル・パス

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testNonExistentSourceFile | 存在しないソースファイルを処理しようとした場合 | .failed ステータスが返され、エラーが記録される |
| testNonExistentDestinationPath | 存在しない保存先パスを指定した場合 | ディレクトリが自動作成されるか、失敗する |

### 2.2 不正なファイル名

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testLongFileName | 200文字の長いファイル名を処理 | 正常に処理される |
| testSpecialCharactersInFileName | スペース、括弧、漢字を含むファイル名を処理 | 正常に処理される |

### 2.3 空のファイル・極端なサイズ

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEmptyFile | 0バイトのファイルを処理 | 正常にコピーされる |
| testLargeFile | 1MBのファイルを処理 | 正常にコピーされる |

### 2.4 イベント名の異常系

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEmptyEventName | 空のイベント名で処理 | フォルダ名に"_"が含まれる形式で保存される |
| testSpecialCharactersInEventName | スラッシュ、コロン、アスタリスクを含むイベント名 | 不正な文字はアンダースコアに置換される |

### 2.5 重複ファイルの異常系

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSameNameDifferentContent | 同名で内容が異なるファイル | 上書きコピーされる |
| testSameSizeDifferentContent | 同名・同サイズで内容が異なるファイル（日時も同じ） | 重複と判定されスキップされる（仕様） |

### 2.6 ディレクトリ関連

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEmptyDirectory | 空のディレクトリをスキャン | ファイルリストは空になる |
| testDeeplyNestedDirectories | 10階層以上ネストしたディレクトリ内のファイルをスキャン | 正常に検出される |

### 2.7 拡張子の異常系

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testCaseInsensitiveExtensions | 大文字小文字混合の拡張子（.JPG, .Jpg, .jPg等） | 全て正しく判定される |
| testDoubleExtensions | 二重拡張子（.backup.jpg, .copy.arw等） | 最後の拡張子で判定される |
| testNoExtension | 拡張子なしのファイル | どの種別にも分類されない |

---

## 3. スキャナー異常系テスト (ScannerErrorTests)

ファイルスキャン時の異常ケースを検証するテスト群です。

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testNonExistentRootDirectory | 存在しないルートディレクトリをスキャン | 空のファイルリストが返される |
| testRootIsFile | ルートパスがファイルの場合 | 空のファイルリストが返される |
| testDirectoryWithNoReadPermission | 読み取り権限のないディレクトリをスキャン | アクセスできないファイルはスキップされる |
| testSymlinkHandling | シンボリックリンクを含むディレクトリをスキャン | リンク先のファイルが正しく検出される |
| testHiddenDirectory | ドットで始まる隠しディレクトリをスキャン | 隠しディレクトリ内のファイルは検出されない |
| testDotFiles | ドットで始まるファイル（.hidden.jpg等）をスキャン | ドットファイルは除外される |
| testMixedContentDirectory | メディアファイルと非メディアファイルが混在するディレクトリ | メディアファイルのみが検出される |
| testCustomRawExtensions | カスタムRAW拡張子（.custom, .raw）を設定 | 設定された拡張子が正しくRAWとして判定される |
| testEmptyRawExtensions | RAW拡張子を空に設定 | RAWファイルは検出されず、JPG/MP4のみ検出される |

---

## 4. 設定異常系テスト (ConfigErrorTests)

設定ファイル読み込み時の異常ケースを検証するテスト群です。

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testInvalidJsonFormat | 不正なJSON形式の設定ファイル | デフォルト設定が使用される |
| testEmptyJsonFile | 空の設定ファイル | デフォルト設定が使用される |
| testEmptyArrayConfig | RawExtensionsが空配列の設定ファイル | デフォルト設定が使用される |
| testInvalidExtensionFormat | 不正な拡張子形式（空文字、ドットのみ等）を含む設定 | 有効な拡張子のみが使用される |
| testMixedValidInvalidExtensions | 有効な拡張子と無効な拡張子が混在する設定 | 有効な拡張子のみが使用される |
| testMissingRawExtensionsKey | RawExtensionsキーが存在しない設定ファイル | デフォルト設定が使用される |

---

## 5. EXIF異常系テスト (ExifErrorTests)

EXIF情報読み込み時の異常ケースを検証するテスト群です。

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testCorruptedFile | 破損した画像ファイル（画像ではない内容） | ファイル作成日時から日付キーが生成される |
| testZeroByteFile | 0バイトのファイル | ファイル作成日時から日付キーが生成される |
| testNonImageFile | 画像ではないファイル（.txt等） | ファイル作成日時から日付キーが生成される |
| testMultipleFilesWithCorrupted | 破損ファイルと正常ファイルが混在 | 正常ファイルから日付が取得される（ファイル名順） |
| testFileWithNoReadPermission | 読み取り権限のないファイル | ファイル作成日時から日付キーが生成される |

---

## 6. 統合テスト (IntegrationTests)

End-to-Endの動作を検証するテスト群です。

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEndToEnd_SDCardSimulation | SDカードのディレクトリ構造（DCIM/100CANON等）を模擬した完全な処理 | RAW/JPG/MP4が正しく分類され、保存先フォルダに配置される |
| testEndToEnd_DuplicateDetection | 同じファイルを2回処理 | 1回目はコピー、2回目は重複スキップされる |
| testEndToEnd_MultipleFormats | 9種類のRAW形式とJPG/MP4を処理 | 全て正しく分類される |
| testEndToEnd_FolderStructure | 保存先フォルダ構造の検証 | [保存先]/[YYYY]/[YYYY-MM-DD]_[イベント名]/[RAW\|JPG\|MP4]/ の構造が作成される |

---

## 7. メディアスキャナー正常系テスト (MediaScannerTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testGetMediaKind_RAW | RAW拡張子（.arw, .cr2, .nef等）の判定 | "RAW" が返される |
| testGetMediaKind_JPG | JPG拡張子（.jpg, .jpeg）の判定 | "JPG" が返される |
| testGetMediaKind_MP4 | 動画拡張子（.mp4, .mov）の判定 | "MP4" が返される |
| testGetMediaKind_Unknown | 非対応拡張子（.txt, .png等）の判定 | nil が返される |
| testCountByType | 複数ファイルの種別カウント | RAW/JPG/MP4の数が正しくカウントされる |
| testEnumerateMediaFiles | ディレクトリ内のメディアファイル列挙 | メディアファイルのみが検出され、ドットファイルは除外される |
| testEnumerateMediaFiles_NestedDirectories | ネストしたディレクトリのスキャン | サブディレクトリ内のファイルも再帰的に検出される |

---

## 8. メディアプロセッサ正常系テスト (MediaProcessorTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSanitizeName | ファイル名のサニタイズ | 不正な文字（/\:*?"<>|）がアンダースコアに置換される |
| testIsSameByTimeAndSize | 同一性判定（サイズと日時） | サイズが同じで日時の差が2秒以内なら同一と判定 |
| testProcessOneFile_Copied | 単一ファイルのコピー | ファイルが正しくコピーされ、JPGフォルダに配置される |
| testProcessOneFile_SkippedDuplicate | 重複ファイルのスキップ | 同一ファイルはスキップされる |
| testProcessOneFile_SkippedUnsupported | 非対応ファイルのスキップ | 非対応拡張子はスキップされる |
| testProcessFiles | 複数ファイルの一括処理 | 全ファイルが正しく処理され、進捗コールバックが呼ばれる |

---

## 9. 設定マネージャー正常系テスト (ConfigManagerTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testNormalizeExtension | 拡張子の正規化 | 先頭ドットの追加、小文字化、トリムが正しく行われる |
| testDefaultRawExtensions | デフォルトRAW拡張子一覧 | 9種類の拡張子が含まれている |
| testLoadConfig_DefaultWhenNoFile | 設定ファイル不存在時 | デフォルト設定が使用される |

---

## 10. EXIFリーダー正常系テスト (ExifReaderTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_EmptyFiles | ファイルリストが空の場合 | 今日の日付が返される |
| testResolveDateKey_NoExifFile | EXIF情報がないファイル | ファイル作成日時から日付キーが生成される |
| testResolveDateKey_SortedByFileName | 複数ファイルの場合 | ファイル名順でソートされた最初のファイルから日付が取得される |

---

## 11. 状態マネージャー正常系テスト (StateManagerTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSaveAndLoadState | 状態の保存と読み込み | 保存した状態が正しく読み込まれる |
| testStatePath | 状態ファイルのパス | ~/Library/Application Support/PhotoOrganizer/state.json に保存される |

---

## テスト実行方法

```bash
# 全テスト実行
make test

# または
swift test

# 詳細出力
swift test --verbose

# 特定テストのみ実行
swift test --filter DataSafetyTests
```

---

## テストカバレッジ

| カテゴリ | テスト数 | 内容 |
|---------|---------|------|
| データ安全性 | 10 | ソース保護、関係ないファイル保護、誤上書き防止 |
| エッジケース | 17 | 異常なファイル名、サイズ、パス |
| スキャナー異常系 | 9 | 権限、シンボリックリンク、隠しファイル |
| 設定異常系 | 6 | 不正なJSON、空の設定 |
| EXIF異常系 | 5 | 破損ファイル、権限なし |
| 統合テスト | 4 | End-to-End処理 |
| 正常系 | 18 | 各モジュールの基本動作 |
| **合計** | **69** | |

---

## 重要な設計原則

1. **ソースファイルは絶対に削除しない** - コピーのみ行い、移動はしない
2. **関係ないファイルには触れない** - メディアファイル以外は無視する
3. **既存の保存先ファイルを上書きしない** - 重複判定で保護する
4. **エラー時でも安全** - 処理中断時もソースファイルは安全
5. **整合性チェック必須** - コピー後に必ず検証する
