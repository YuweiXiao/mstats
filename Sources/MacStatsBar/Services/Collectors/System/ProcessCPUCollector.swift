import Foundation

public protocol ProcessCPUCollecting {
    func collectProcessCPUUsages() -> [ProcessCPUUsage]
}

public final class ProcessCPUCollector: ProcessCPUCollecting {
    typealias CommandRunner = (_ executablePath: String, _ arguments: [String]) throws -> String
    typealias LogicalCPUCountProvider = () -> Int

    private let commandRunner: CommandRunner
    private let logicalCPUCountProvider: LogicalCPUCountProvider

    public init() {
        logicalCPUCountProvider = { ProcessInfo.processInfo.activeProcessorCount }
        commandRunner = Self.runCommand
    }

    init(
        logicalCPUCountProvider: @escaping LogicalCPUCountProvider = { ProcessInfo.processInfo.activeProcessorCount },
        commandRunner: @escaping CommandRunner
    ) {
        self.logicalCPUCountProvider = logicalCPUCountProvider
        self.commandRunner = commandRunner
    }

    public func collectProcessCPUUsages() -> [ProcessCPUUsage] {
        do {
            let output = try commandRunner("/bin/ps", ["-Aceo", "pcpu=,comm="])
            let logicalCPUCount = max(1, logicalCPUCountProvider())
            return Self.parse(output: output, logicalCPUCount: logicalCPUCount)
        } catch {
            return []
        }
    }

    static func parse(output: String, logicalCPUCount: Int = 1) -> [ProcessCPUUsage] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { parse(line: $0, logicalCPUCount: logicalCPUCount) }
    }

    private static func parse(line: Substring, logicalCPUCount: Int) -> ProcessCPUUsage? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else {
            return nil
        }

        let parts = trimmedLine.split(
            maxSplits: 1,
            omittingEmptySubsequences: true,
            whereSeparator: \.isWhitespace
        )
        guard parts.count == 2 else {
            return nil
        }
        guard let rawCPU = Double(parts[0]), rawCPU.isFinite, rawCPU >= 0 else {
            return nil
        }

        let rawName = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawName.isEmpty else {
            return nil
        }

        let normalizedCPU = rawCPU / Double(max(1, logicalCPUCount))
        return ProcessCPUUsage(processName: rawName, cpuUsagePercent: normalizedCPU)
    }

    private static func runCommand(executablePath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ProcessCPUCollectorError.commandFailed(status: Int(process.terminationStatus))
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
    }
}

private enum ProcessCPUCollectorError: Error {
    case commandFailed(status: Int)
}
