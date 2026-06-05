import Foundation

protocol MediaScanning {
    func enumerateMediaFiles(root: String) -> [String]
    func getMediaKind(_ path: String) -> String?
    func countByType(_ files: [String]) -> (raw: Int, jpg: Int, mp4: Int)
}

class MediaScanner: MediaScanning {
    let rawExtensions: Set<String>

    init(rawExtensions: Set<String>) {
        self.rawExtensions = rawExtensions
    }

    func enumerateMediaFiles(root: String) -> [String] {
        var results: [String] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: root) else { return results }

        while let relativePath = enumerator.nextObject() as? String {
            let fullPath = (root as NSString).appendingPathComponent(relativePath)
            let name = (relativePath as NSString).lastPathComponent

            if name.hasPrefix(".") {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    enumerator.skipDescendants()
                }
                continue
            }

            if getMediaKind(fullPath) != nil {
                results.append(fullPath)
            }
        }
        return results
    }

    func getMediaKind(_ path: String) -> String? {
        let ext = (path as NSString).pathExtension.lowercased()
        if rawExtensions.contains(".\(ext)") || rawExtensions.contains(ext) { return "RAW" }
        if ext == "jpg" || ext == "jpeg" { return "JPG" }
        if ext == "mp4" || ext == "mov" { return "MP4" }
        return nil
    }

    func countByType(_ files: [String]) -> (raw: Int, jpg: Int, mp4: Int) {
        var raw = 0, jpg = 0, mp4 = 0
        for f in files {
            switch getMediaKind(f) {
            case "RAW": raw += 1
            case "JPG": jpg += 1
            case "MP4": mp4 += 1
            default: break
            }
        }
        return (raw, jpg, mp4)
    }
}
