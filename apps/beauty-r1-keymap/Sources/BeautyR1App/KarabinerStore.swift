import Foundation
import BeautyR1Core

enum StoreError: LocalizedError {
    case missingCLI
    case lintFailed(String)
    case verificationFailed
    case noBackup

    var errorDescription: String? {
        switch self {
        case .missingCLI: "找不到 Karabiner CLI。請確認 Karabiner-Elements 已安裝。"
        case .lintFailed(let output): "Karabiner 規則檢查失敗：\n\(output)"
        case .verificationFailed: "寫入後的設定檔與預期不符。"
        case .noBackup: "找不到可以還原的備份。"
        }
    }
}

enum KarabinerStore {
    static let configURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/karabiner/karabiner.json")
    static let backupDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/BeautyR1Keymap/Backups")
    static let cliURL = URL(fileURLWithPath: "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli")

    static func load() throws -> (KeymapSettings, Bool) {
        let data = try Data(contentsOf: configURL)
        if let settings = KarabinerKeymap.currentSettings(from: data) {
            return (settings, true)
        }
        return (KeymapSettings(), false)
    }

    static func apply(_ settings: KeymapSettings) throws -> URL {
        let original = try Data(contentsOf: configURL)
        let updated = try KarabinerKeymap.updatedConfiguration(original, settings: settings)
        if let ruleData = try KarabinerKeymap.standaloneRuleData(for: settings) {
            try lint(ruleData)
        }
        let backup = try makeBackup(of: original)
        do {
            try updated.write(to: configURL, options: .atomic)
            guard try Data(contentsOf: configURL) == updated else {
                throw StoreError.verificationFailed
            }
        } catch {
            try? original.write(to: configURL, options: .atomic)
            throw error
        }
        return backup
    }

    static func latestBackup() -> URL? {
        let files = try? FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: nil
        )
        return files?.filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    static func restoreLatest() throws -> URL {
        guard let source = latestBackup() else { throw StoreError.noBackup }
        let backupData = try Data(contentsOf: source)
        _ = try JSONSerialization.jsonObject(with: backupData)
        let current = try Data(contentsOf: configURL)
        _ = try makeBackup(of: current)
        try backupData.write(to: configURL, options: .atomic)
        guard try Data(contentsOf: configURL) == backupData else {
            throw StoreError.verificationFailed
        }
        return source
    }

    private static func makeBackup(of data: Data) throws -> URL {
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let name = "karabiner-\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(6)).json"
        let url = backupDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func lint(_ ruleData: Data) throws {
        guard FileManager.default.isExecutableFile(atPath: cliURL.path) else {
            throw StoreError.missingCLI
        }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("beauty-r1-\(UUID().uuidString).json")
        try ruleData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let process = Process()
        process.executableURL = cliURL
        process.arguments = ["--lint-complex-modifications", tempURL.path]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "未知錯誤"
            throw StoreError.lintFailed(text)
        }
    }
}
