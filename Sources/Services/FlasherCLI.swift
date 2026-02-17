import Foundation

// MARK: - Data Models

struct VersionInfo: Codable {
    let version: String
    let url: String
    let sha256: String
}

struct VersionList: Codable {
    let latest: VersionInfo?
    let releases: [VersionInfo]
}

enum FlashStep: Int, CaseIterable {
    case checking = 1
    case downloading = 2
    case extracting = 3
    case waitingForDevice = 4
    case flashing = 5
    case complete = 6
    
    var title: String {
        switch self {
        case .checking: return "Checking"
        case .downloading: return "Downloading"
        case .extracting: return "Extracting"
        case .waitingForDevice: return "Waiting for Device"
        case .flashing: return "Flashing"
        case .complete: return "Complete"
        }
    }
    
    var isCancellationSafe: Bool {
        switch self {
        case .checking, .downloading, .extracting, .waitingForDevice:
            return true
        case .flashing, .complete:
            return false
        }
    }
    
    static var totalSteps: Int { 5 }  // Not counting complete
}

enum FlashProgress {
    case step(FlashStep, message: String)
    case success
    case error(String)
    
    var currentStep: FlashStep {
        switch self {
        case .step(let step, _): return step
        case .success: return .complete
        case .error: return .checking
        }
    }
    
    var message: String {
        switch self {
        case .step(_, let msg): return msg
        case .success: return "Flash completed successfully!"
        case .error(let msg): return msg
        }
    }
}

enum FlasherError: LocalizedError {
    case cliNotFound
    case executionFailed(String)
    case parseError(String)
    case insufficientDiskSpace(available: Int64, required: Int64)
    
    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "arduino-flasher-cli not found in app bundle"
        case .executionFailed(let message):
            return "Flash failed: \(message)"
        case .parseError(let message):
            return "Failed to parse CLI output: \(message)"
        case .insufficientDiskSpace(let available, let required):
            let availableGB = Double(available) / 1_000_000_000
            let requiredGB = Double(required) / 1_000_000_000
            return String(format: "Insufficient disk space. You have %.1f GB available but need at least %.0f GB free to download and flash the image.", availableGB, requiredGB)
        }
    }
}

// MARK: - FlasherCLI

class FlasherCLI {
    /// Minimum required disk space in bytes (12 GB)
    static let requiredDiskSpace: Int64 = 12_000_000_000
    
    private var cliPath: String {
        // First try bundle resources
        if let bundlePath = Bundle.main.path(forResource: "arduino-flasher-cli", ofType: nil) {
            return bundlePath
        }
        // Fallback to known location during development
        let devPath = "\(NSHomeDirectory())/Downloads/arduino-flasher-cli-0.5.0-darwin-arm64/arduino-flasher-cli"
        if FileManager.default.fileExists(atPath: devPath) {
            return devPath
        }
        return "arduino-flasher-cli"
    }
    
    /// Check available disk space
    func checkDiskSpace() throws {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        
        if let available = values.volumeAvailableCapacityForImportantUsage {
            if available < Self.requiredDiskSpace {
                throw FlasherError.insufficientDiskSpace(available: available, required: Self.requiredDiskSpace)
            }
        }
    }
    
    /// Returns available disk space in bytes
    func availableDiskSpace() -> Int64? {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }
    
    /// Fetches available firmware versions
    func listVersions() async throws -> VersionList {
        let (output, _) = try await runCLI(arguments: ["list", "--format", "json"])
        
        guard let data = output.data(using: .utf8) else {
            throw FlasherError.parseError("Invalid output encoding")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VersionList.self, from: data)
    }
    
    /// Flashes the latest firmware, streaming progress updates
    func flashLatest() -> AsyncStream<FlashProgress> {
        AsyncStream { continuation in
            Task {
                do {
                    // Check disk space first
                    continuation.yield(.step(.checking, message: "Checking disk space..."))
                    try self.checkDiskSpace()
                    
                    // Signal we're starting the download
                    continuation.yield(.step(.downloading, message: "Starting download..."))
                    
                    try await self.streamFlash(arguments: ["flash", "latest", "-y"], continuation: continuation)
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }
    
    /// Flashes a specific version
    func flash(version: String) -> AsyncStream<FlashProgress> {
        AsyncStream { continuation in
            Task {
                do {
                    continuation.yield(.step(.checking, message: "Checking disk space..."))
                    try self.checkDiskSpace()
                    
                    continuation.yield(.step(.downloading, message: "Starting download..."))
                    try await self.streamFlash(arguments: ["flash", version, "-y"], continuation: continuation)
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func runCLI(arguments: [String]) async throws -> (stdout: String, stderr: String) {
        let path = cliPath
        guard FileManager.default.fileExists(atPath: path) else {
            throw FlasherError.cliNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        process.waitUntilExit()
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        return (stdout, stderr)
    }
    
    private func streamFlash(arguments: [String], continuation: AsyncStream<FlashProgress>.Continuation) async throws {
        let path = cliPath
        guard FileManager.default.fileExists(atPath: path) else {
            throw FlasherError.cliNotFound
        }
        
        // Reset step tracking
        currentStep = .downloading
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Handle stdout - process any available data immediately
        // CLI uses \r for progress updates, so we split on both \n and \r
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let text = String(data: data, encoding: .utf8) else { return }
            
            // Split on both newlines and carriage returns
            let lines = text.components(separatedBy: CharacterSet(charactersIn: "\r\n"))
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    self?.parseOutputLine(trimmed, continuation: continuation)
                }
            }
        }
        
        // Handle stderr
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let text = String(data: data, encoding: .utf8) else { return }
            
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.lowercased().contains("error") {
                continuation.yield(.error(trimmed))
            }
        }
        
        try process.run()
        
        // Wait for process to complete
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                cont.resume()
            }
        }
        
        // Clean up handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        
        if process.terminationStatus == 0 {
            continuation.yield(.success)
        } else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
            if !stderr.isEmpty {
                continuation.yield(.error(stderr))
            }
        }
        
        continuation.finish()
    }
    
    // Track current step for context
    private var currentStep: FlashStep = .downloading
    
    private func parseOutputLine(_ rawLine: String, continuation: AsyncStream<FlashProgress>.Continuation) {
        let lines = rawLine.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let lower = trimmed.lowercased()
            let percent = extractPercentage(from: trimmed)
            
            // Check for stage transitions and emit step updates
            if lower.contains("checking") || lower.contains("found debian") || lower.contains("image version") {
                currentStep = .downloading
                continuation.yield(.step(.downloading, message: trimmed))
            } else if lower.contains("downloading") || lower.contains("download") || (percent != nil && currentStep == .downloading) {
                currentStep = .downloading
                let message = cleanProgressMessage(from: trimmed, stage: "Downloading")
                continuation.yield(.step(.downloading, message: message))
            } else if lower.contains("extracting") || lower.contains("extract") {
                currentStep = .extracting
                continuation.yield(.step(.extracting, message: trimmed))
            } else if lower.contains("waiting for edl") || lower.contains("waiting for device") {
                currentStep = .waitingForDevice
                continuation.yield(.step(.waitingForDevice, message: "Connect your UNO Q with jumper installed..."))
            } else if lower.contains("flashing") || lower.contains("qdl") {
                currentStep = .flashing
                continuation.yield(.step(.flashing, message: trimmed))
            } else if lower.contains("flashed") || lower.contains("patches applied") {
                currentStep = .flashing
                continuation.yield(.step(.flashing, message: trimmed))
            } else if lower.contains("partition 0 is now bootable") || lower.contains("successfully") {
                continuation.yield(.success)
            } else if percent != nil {
                // Line has a percentage - update current step
                let message = cleanProgressMessage(from: trimmed, stage: currentStep.title)
                continuation.yield(.step(currentStep, message: message))
            }
            // Ignore lines without useful info
        }
    }
    
    /// Extract percentage from output line
    /// Handles formats like: "24% |████████" or "50%" or "[50%]"
    private func extractPercentage(from text: String) -> Double? {
        // First try to match percentage at the start of line (CLI progress format)
        // Pattern: starts with digits followed by %
        let startPattern = #"^\s*(\d+(?:\.\d+)?)\s*%"#
        if let regex = try? NSRegularExpression(pattern: startPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let value = Double(text[range]) {
            return value / 100.0
        }
        
        // Fallback: match percentage anywhere in the text
        let anyPattern = #"(\d+(?:\.\d+)?)\s*%"#
        if let regex = try? NSRegularExpression(pattern: anyPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let value = Double(text[range]) {
            return value / 100.0
        }
        
        return nil
    }
    
    /// Extract a cleaner message from progress output
    /// Converts "24% |████████    | 500MB/2.1GB" to "Downloading: 24% (500MB/2.1GB)"
    private func cleanProgressMessage(from text: String, stage: String) -> String {
        // Extract percentage
        let percentPattern = #"^\s*(\d+)\s*%"#
        var percent: String? = nil
        if let regex = try? NSRegularExpression(pattern: percentPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            percent = String(text[range])
        }
        
        // Extract size info like "500MB/2.1GB"
        let sizePattern = #"(\d+(?:\.\d+)?\s*[KMGT]?B\s*/\s*\d+(?:\.\d+)?\s*[KMGT]?B)"#
        var sizeInfo: String? = nil
        if let regex = try? NSRegularExpression(pattern: sizePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            sizeInfo = String(text[range])
        }
        
        // Build clean message
        if let p = percent, let s = sizeInfo {
            return "\(stage): \(p)% (\(s))"
        } else if let p = percent {
            return "\(stage): \(p)%"
        } else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
