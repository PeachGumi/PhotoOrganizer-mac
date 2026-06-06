# PhotoOrganizer テスト仕様書

## テスト結果サマリー

- **総テスト数**: 143
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

### 1.7 コンテンツ完全性

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testCopiedContentMatchesSource | コピーされたファイルの内容がソースと完全に一致することを確認 | 全ファイルの内容がバイト単位で一致する |
| testMultipleRunsPreserveData | 同一ファイルを5回処理してもソースが安全であることを確認 | ソースファイルは変更されず保持される |
| testDestinationAutoCreated | 保存先パスが深くネストしていても自動作成されることを確認 | ディレクトリが自動作成され、処理が成功する |
| testAllFileTypesClassifiedCorrectly | RAW/JPG/MP4の全ファイルが正しく分類されることを確認 | 各ファイルが正しいサブディレクトリに配置される |

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

### 2.8 Unicode・国際化

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testUnicodeFileName | 日本語を含むファイル名（写真_001.JPG等） | 正常に処理される |
| testJapaneseEventName | 日本語のイベント名（旅行_2024等） | フォルダ名に日本語が保持される |
| testLongEventName | 200文字の長いイベント名 | 正常にフォルダ名として使用される |

### 2.9 特殊ケース

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSingleCharacterFileName | 1文字のファイル名（a.JPG等） | 正常に処理される |
| testFileNameWithSpaces | スペースと括弧を含むファイル名 | 正常に処理される |
| testManyFilesInBatch | 50ファイルの一括処理 | 全ファイルが正常に処理される |
| testSameExifDateDifferentEvents | 同一EXIF日付で異なるイベント名 | 別のフォルダが作成される |

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
| testJpegWithoutExifData | EXIF情報なしのJPEG画像 | ファイル作成日時から日付キーが生成される |
| testTruncatedJpegFile | 切り詰められたJPEGファイル | 作成日時フォールバックまたは有効な日付キー |
| testFakeImageFileReturnsNil | 非画像データを.jpg拡張子で保存 | readExifDateがnilを返す |
| testNonExistentFileReturnsNil | 存在しないファイルパス | readExifDateがnilを返す |
| testDirectoryPathReturnsNil | ディレクトリパスを指定 | readExifDateがnilを返す |
| testAllFilesCorruptedReturnsCreationDate | 全ファイルが破損 | 最初のファイルの作成日時が使用される |

---

## 6. 統合テスト (IntegrationTests)

End-to-Endの動作を検証するテスト群です。

### 6.1 基本End-to-End

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEndToEnd_SDCardSimulation | SDカードのディレクトリ構造（DCIM/100CANON等）を模擬した完全な処理 | RAW/JPG/MP4が正しく分類され、保存先フォルダに配置される |
| testEndToEnd_DuplicateDetection | 同じファイルを2回処理 | 1回目はコピー、2回目は重複スキップされる |
| testEndToEnd_MultipleFormats | 9種類のRAW形式とJPG/MP4を処理 | 全て正しく分類される |

### 6.2 EXIF日付に基づくフォルダ構造

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEndToEnd_FolderStructureFromExif | EXIF DateTimeOriginalの日付でフォルダ作成 | [保存先]/2023/2023-03-15_ExifTest/ 構造が作成される |
| testEndToEnd_FolderStructureFromExifDigitized | EXIF DateTimeDigitizedの日付でフォルダ作成 | DateTimeOriginal不在時にDigitizedが使用される |
| testEndToEnd_MultipleEventsDifferentExifDates | 異なるEXIF日付のファイルを別イベントで処理 | 各イベントが正しい日付フォルダに配置される |
| testEndToEnd_FolderStructure | 保存先フォルダ構造の検証 | [保存先]/[YYYY]/[YYYY-MM-DD]_[イベント名]/[RAW\|JPG\|MP4]/ の構造が作成される |

### 6.3 データ完全性

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEndToEnd_ContentPreservedAfterProcess | 処理後にファイル内容が保持される | コピー元とコピー先の内容が完全に一致する |
| testEndToEnd_SourceFilesUnchanged | 処理後もソースファイルが変更されない | サイズ・日時・内容すべて変更されない |
| testEndToEnd_MultipleBatches | 3バッチ連続処理 | 各バッチが正常に完了し、データが保持される |
| testEndToEnd_EmptySDCard | 空のSDカードを処理 | 0ファイルで正常完了 |

---

## 7. メディアスキャナー正常系テスト (MediaScannerTests)

### 7.1 getMediaKind

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testGetMediaKind_RAW | RAW拡張子（.arw, .cr2, .nef等）の判定 | "RAW" が返される |
| testGetMediaKind_AllRawFormats | 全9種類のRAW拡張子の判定 | 全て"RAW"が返される |
| testGetMediaKind_JPG | JPG拡張子（.jpg, .jpeg）の判定 | "JPG" が返される |
| testGetMediaKind_MP4 | 動画拡張子（.mp4, .mov）の判定 | "MP4" が返される |
| testGetMediaKind_Unknown | 非対応拡張子（.txt, .png等）の判定 | nil が返される |
| testGetMediaKind_CommonNonMediaFormats | 一般的な非メディア形式（.png, .gif, .pdf等） | nil が返される |

### 7.2 countByType

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testCountByType | 複数ファイルの種別カウント | RAW/JPG/MP4の数が正しくカウントされる |
| testCountByType_EmptyList | 空のリスト | 全て0が返される |
| testCountByType_OnlyRaw | RAWファイルのみ | raw=3, jpg=0, mp4=0 |
| testCountByType_OnlyJpg | JPGファイルのみ | raw=0, jpg=2, mp4=0 |
| testCountByType_OnlyMp4 | MP4ファイルのみ | raw=0, jpg=0, mp4=2 |
| testCountByType_NoMediaFiles | 非メディアファイルのみ | 全て0が返される |

### 7.3 enumerateMediaFiles

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testEnumerateMediaFiles | ディレクトリ内のメディアファイル列挙 | メディアファイルのみが検出され、ドットファイルは除外される |
| testEnumerateMediaFiles_NestedDirectories | ネストしたディレクトリのスキャン | サブディレクトリ内のファイルも再帰的に検出される |
| testEnumerateMediaFiles_EmptyDirectory | 空のディレクトリ | 空のリストが返される |
| testEnumerateMediaFiles_NonExistentDirectory | 存在しないディレクトリ | 空のリストが返される |
| testEnumerateMediaFiles_HiddenDirectorySkipped | 隠しディレクトリのスキップ | ドット始まりディレクトリ内はスキャンされない |
| testEnumerateMediaFiles_DotFilesSkipped | ドットファイルのスキップ | .DS_Store, .hidden.jpg等が除外される |
| testEnumerateMediaFiles_SdCardStructure | SDカード構造（DCIM/100CANON等）の模拟 | 全ファイルが正しく検出される |
| testEnumerateMediaFiles_MixedMediaTypes | 複数種別のメディアが混在 | 各ファイルが正しく分類される |

---

## 8. メディアプロセッサ正常系テスト (MediaProcessorTests)

### 8.1 サニタイズ・同一性判定

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testSanitizeName | ファイル名のサニタイズ | 不正な文字（/\:*?"<>|）がアンダースコアに置換される |
| testSanitizeName_EmptyString | 空文字列のサニタイズ | 空文字列が返される |
| testSanitizeName_AllInvalidChars | 全不正文字を含む | 全てアンダースコアに置換される |
| testSanitizeName_JapaneseCharacters | 日本語を含む名前 | 日本語は保持される |
| testIsSameByTimeAndSize | 同一性判定（サイズと日時） | サイズが同じで日時の差が2秒以内なら同一と判定 |

### 8.2 単一ファイル処理

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testProcessOneFile_Copied | 単一ファイルのコピー | ファイルが正しくコピーされ、JPGフォルダに配置される |
| testProcessOneFile_RawFile | RAWファイルの処理 | RAWフォルダに配置される |
| testProcessOneFile_Mp4File | MP4ファイルの処理 | MP4フォルダに配置される |
| testProcessOneFile_SkippedDuplicate | 重複ファイルのスキップ | 同一ファイルはスキップされる |
| testProcessOneFile_SkippedUnsupported | 非対応ファイルのスキップ | 非対応拡張子はスキップされる |
| testProcessOneFile_ContentPreserved | コピー後の内容保持 | 特殊文字含む内容も完全に保持される |
| testProcessOneFile_ModificationDatePreserved | 更新日時の保持 | コピー元の更新日時がコピー先に設定される |

### 8.3 一括処理

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testProcessFiles | 複数ファイルの一括処理 | 全ファイルが正しく処理され、進捗コールバックが呼ばれる |
| testProcessFiles_EmptyFileList | 空ファイルリスト | 0件で正常完了 |
| testProcessFiles_OnlyRaw | RAWファイルのみ | raw=2, jpg=0, mp4=0 |
| testProcessFiles_OnlyJpg | JPGファイルのみ | raw=0, jpg=2, mp4=0 |
| testProcessFiles_OnlyMp4 | MP4ファイルのみ | raw=0, jpg=0, mp4=2 |
| testProcessFiles_ProgressCallback | 進捗コールバックの検証 | ファイル数分コールバックされ、totalが一定 |
| testProcessFiles_FolderStructureFromExif | EXIF日付のフォルダ構造 | 2023/2023-03-15_EventName/ 構造が作成される |
| testProcessFiles_NonExistentFileFails | 存在しないファイルの処理 | failed=1, errorsに記録される |
| testProcessFiles_MixedValidAndInvalid | 有効/無効ファイル混在 | 有効ファイルは処理、無効ファイルは失敗 |

---

## 9. 設定マネージャー正常系テスト (ConfigManagerTests)

### 9.1 拡張子正規化

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testNormalizeExtension | 拡張子の正規化 | 先頭ドットの追加、小文字化、トリムが正しく行われる |
| testNormalizeExtension_DotOnly | ドットのみの拡張子（"."や".."） | nilが返される |
| testNormalizeExtension_WhitespaceOnly | 空白のみの文字列 | nilが返される |

### 9.2 デフォルト設定

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testDefaultRawExtensions | デフォルトRAW拡張子一覧 | 9種類の拡張子が含まれている |

### 9.3 設定ファイル読み込み

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testLoadConfig_DefaultWhenNoFile | 設定ファイル不存在時 | デフォルト設定が使用される |
| testLoadConfig_ValidConfigFile | 有効な設定ファイル | 設定値が読み込まれる |
| testLoadConfig_ExtensionWithoutDot | ドットなし拡張子 | ドットが自動追加される |
| testLoadConfig_UppercaseExtensions | 大文字拡張子 | 小文字に正規化される |
| testLoadConfig_DuplicateExtensions | 重複拡張子 | Setにより重複排除される |
| testLoadConfig_ExtraKeys | 未知のキーを含む | 無視され、正常に読み込まれる |

---

## 10. EXIFリーダー正常系テスト (ExifReaderTests)

### 10.1 基本フォールバック

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_EmptyFiles | ファイルリストが空の場合 | 今日の日付が返される |
| testResolveDateKey_NoExifFile | EXIF情報がないファイル | ファイル作成日時から日付キーが生成される |

### 10.2 EXIF DateTimeOriginal

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_ExifDateTimeOriginal | EXIF DateTimeOriginalから日付取得 | "2023-03-15"形式で返される |
| testResolveDateKey_ExifDateTimeOriginal_YearBoundary | 年境界の日付（元日、大晦日） | "2024-01-01", "2023-12-31"が正しく返される |
| testResolveDateKey_ExifDateTimeOriginal_LegacyYear | 古い年（2005年等） | "2005-06-15"が正しく返される |

### 10.3 EXIF DateTimeDigitized フォールバック

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_ExifDateTimeDigitizedFallback | DateTimeOriginal不在時 | DateTimeDigitizedから日付取得 |
| testResolveDateKey_ExifDateTimeOriginalTakesPrecedence | 両方存在時 | DateTimeOriginalが優先される |

### 10.4 複数ファイルのEXIF解決

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_MultipleFilesFirstHasExif | 先頭ファイルがEXIF持つ | 先頭ファイルのEXIFが使用される |
| testResolveDateKey_MultipleFilesFirstNoExifSecondHasExif | 先頭EXIFなし、2番目EXIFあり | 先頭の作成日時フォールバック |
| testResolveDateKey_MultipleFilesAllHaveExif | 全ファイルEXIF持つ | 先頭（ソート後）のEXIFが使用される |

### 10.5 ファイル名ソート

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testResolveDateKey_SortedByFileName | 複数ファイルの場合 | ファイル名順でソートされた最初のファイルから日付が取得される |
| testResolveDateKey_SortedCaseInsensitive | 大文字小文字無視のソート | ケースインセンシティブでソートされる |

### 10.6 readExifDate直接テスト

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testReadExifDate_ValidExif | 有効なEXIFの日付読み込み | Dateオブジェクトが返される |
| testReadExifDate_NonImageReturnsNil | 非画像ファイル | nilが返される |
| testReadExifDate_JpegWithoutExifReturnsNil | EXIFなしJPEG | nilが返される |
| testReadExifDate_NonExistentPathReturnsNil | 存在しないパス | nilが返される |

---

## 11. 状態マネージャー正常系テスト (StateManagerTests)

| テスト名 | 内容 | 想定結果 |
|---------|------|---------|
| testStatePath | 状態ファイルのパス | ~/Library/Application Support/PhotoOrganizer/state.json に保存される |
| testStatePath_IsInUserDomain | パスがユーザーディレクトリ配下 | ホームディレクトリから始まる |
| testStateDirectory_IsCreated | 状態ディレクトリの自動作成 | ディレクトリが存在する |
| testSaveState_ReturnsTrue | 状態保存の成功 | trueが返される |

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
swift test --filter ExifReaderTests
swift test --filter IntegrationTests
```

---

## テストカバレッジ

| カテゴリ | テスト数 | 内容 |
|---------|---------|------|
| データ安全性 | 14 | ソース保護、関係ないファイル保護、誤上書き防止、コンテンツ完全性 |
| エッジケース | 24 | 異常なファイル名、サイズ、パス、Unicode、大量ファイル |
| スキャナー異常系 | 9 | 権限、シンボリックリンク、隠しファイル |
| 設定異常系 | 6 | 不正なJSON、空の設定 |
| EXIF異常系 | 11 | 破損ファイル、権限なし、EXIFなしJPEG |
| 統合テスト | 11 | End-to-End処理、EXIFフォルダ構造、データ完全性 |
| メディアスキャナー | 20 | getMediaKind、countByType、enumerateMediaFiles |
| メディアプロセッサ | 21 | サニタイズ、同一性判定、単一/一括処理 |
| 設定マネージャー | 10 | 拡張子正規化、デフォルト設定、設定ファイル読み込み |
| EXIFリーダー | 16 | EXIF日付解決、フォールバック、複数ファイル |
| 状態マネージャー | 4 | パス検証、ディレクトリ作成、保存 |
| **合計** | **143** | |

---

## テストヘルパー

### TestImageHelper

実JPEG画像を生成し、EXIFデータを埋め込むテストヘルパーです。

```swift
TestImageHelper.createJPEGWithExif(
    at: path,
    dateTimeOriginal: "2023:03:15 14:30:00",
    dateTimeDigitized: "2022:07:20 10:00:00"
)
```

- ImageIOフレームワークを使用して実際のJPEG画像を生成
- EXIF DateTimeOriginal/DateTimeDigitizedを埋め込み可能
- 実画像を使用するため、EXIF読み込みの正常系をテスト可能

---

## 重要な設計原則

1. **ソースファイルは絶対に削除しない** - コピーのみ行い、移動はしない
2. **関係ないファイルには触れない** - メディアファイル以外は無視する
3. **既存の保存先ファイルを上書きしない** - 重複判定で保護する
4. **エラー時でも安全** - 処理中断時もソースファイルは安全
5. **整合性チェック必須** - コピー後に必ず検証する
6. **EXIF日付を優先** - DateTimeOriginal > DateTimeDigitized > ファイル作成日時の順
