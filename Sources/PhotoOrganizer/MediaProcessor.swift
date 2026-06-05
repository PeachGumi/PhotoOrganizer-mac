import Foundation

protocol MediaProcessing {
    func processFiles(
        _ files: [String],
        destination: String,
        eventName: String,
        onProgress: @escaping (Int, Int) -> Void
    ) async -> ProcessResult
    func processOneFile(_ src: String, basePath: String, errors: inout [String: String]) -> FileProcessStatus
    func isSameByTimeAndSize(srcSize: Int, srcDate: Date, dstSize: Int, dstDate: Date) -> Bool
    func sanitizeName(_ name: String) -> String
}

class MediaProcessor: MediaProcessing {
    let scanner: MediaScanning

    init(scanner: MediaScanning) {
        self.scanner = scanner
    }

    func processFiles(
        _ files: [String],
        destination: String,
        eventName: String,
        onProgress: @escaping (Int, Int) -> Void
    ) async -> ProcessResult {
        let dateKey = ExifReader.resolveDateKey(files: files)
        let sanitizedEvent = sanitizeName(eventName)
        let folderName = "\(dateKey)_\(sanitizedEvent)"
        let yearPath = (destination as NSString).appendingPathComponent(String(dateKey.prefix(4)))
        let basePath = (yearPath as NSString).appendingPathComponent(folderName)

        let fm = FileManager.default
        try? fm.createDirectory(atPath: (basePath as NSString).appendingPathComponent("RAW"), withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: (basePath as NSString).appendingPathComponent("JPG"), withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: (basePath as NSString).appendingPathComponent("MP4"), withIntermediateDirectories: true)

        var raw = 0, jpg = 0, mp4 = 0, skipUnsupported = 0, skipDuplicate = 0, failed = 0
        var failedFiles: [String] = []
        var errors: [String: String] = [:]

        for (index, src) in files.enumerated() {
            let kind = scanner.getMediaKind(src)
            switch kind {
            case "RAW": raw += 1
            case "JPG": jpg += 1
            case "MP4": mp4 += 1
            default: break
            }

            let status = processOneFile(src, basePath: basePath, errors: &errors)
            switch status {
            case .skippedUnsupported: skipUnsupported += 1
            case .skippedDuplicate: skipDuplicate += 1
            case .failed:
                failed += 1
                failedFiles.append(src)
            case .copied: break
            }

            onProgress(index + 1, files.count)
        }

        if !failedFiles.isEmpty {
            try? await Task.sleep(nanoseconds: 800_000_000)
            failed = 0
            for src in failedFiles {
                let retryStatus = processOneFile(src, basePath: basePath, errors: &errors)
                if retryStatus == .failed {
                    failed += 1
                }
            }
        }

        return ProcessResult(
            raw: raw,
            jpg: jpg,
            mp4: mp4,
            skipUnsupported: skipUnsupported,
            skipDuplicate: skipDuplicate,
            failed: failed,
            basePath: basePath,
            errors: errors
        )
    }

    func processOneFile(_ src: String, basePath: String, errors: inout [String: String]) -> FileProcessStatus {
        guard let kind = scanner.getMediaKind(src) else { return .skippedUnsupported }

        let fileName = (src as NSString).lastPathComponent
        let dst = (basePath as NSString).appendingPathComponent("\(kind)/\(fileName)")
        let fm = FileManager.default

        do {
            let srcAttrs = try fm.attributesOfItem(atPath: src)
            let srcSize = srcAttrs[.size] as? Int ?? 0
            let srcDate = srcAttrs[.modificationDate] as? Date ?? Date()

            if fm.fileExists(atPath: dst) {
                let dstAttrs = try fm.attributesOfItem(atPath: dst)
                let dstSize = dstAttrs[.size] as? Int ?? 0
                let dstDate = dstAttrs[.modificationDate] as? Date ?? Date()

                if isSameByTimeAndSize(srcSize: srcSize, srcDate: srcDate, dstSize: dstSize, dstDate: dstDate) {
                    return .skippedDuplicate
                }

                try fm.removeItem(atPath: dst)
            }

            try fm.copyItem(atPath: src, toPath: dst)
            try fm.setAttributes([.modificationDate: srcDate], ofItemAtPath: dst)

            let copiedAttrs = try fm.attributesOfItem(atPath: dst)
            let copiedSize = copiedAttrs[.size] as? Int ?? 0
            let copiedDate = copiedAttrs[.modificationDate] as? Date ?? Date()

            if !isSameByTimeAndSize(srcSize: srcSize, srcDate: srcDate, dstSize: copiedSize, dstDate: copiedDate) {
                errors[src] = "整合性チェック失敗"
                return .failed
            }

            return .copied
        } catch {
            errors[src] = error.localizedDescription
            return .failed
        }
    }

    func isSameByTimeAndSize(srcSize: Int, srcDate: Date, dstSize: Int, dstDate: Date) -> Bool {
        if srcSize != dstSize { return false }
        return abs(srcDate.timeIntervalSince(dstDate)) <= 2.0
    }

    func sanitizeName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidChars).joined(separator: "_")
    }
}
