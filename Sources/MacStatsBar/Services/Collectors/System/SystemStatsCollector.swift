import Foundation

public struct SystemStatsCollector: StatsCollecting {
    private let cpuCollector: any CPUCollecting
    private let memoryCollector: any MemoryCollecting
    private let networkCollector: any NetworkCollecting
    private let batteryCollector: any BatteryCollecting
    private let diskCollector: any DiskCollecting
    private let processCPUCollector: any ProcessCPUCollecting

    public init(
        cpu: any CPUCollecting = CPUCollector(),
        memory: any MemoryCollecting = MemoryCollector(),
        network: any NetworkCollecting = NetworkCollector(),
        battery: any BatteryCollecting = BatteryCollector(),
        disk: any DiskCollecting = DiskCollector(),
        processCPU: any ProcessCPUCollecting = ProcessCPUCollector()
    ) {
        self.cpuCollector = cpu
        self.memoryCollector = memory
        self.networkCollector = network
        self.batteryCollector = battery
        self.diskCollector = disk
        processCPUCollector = processCPU
    }

    public func collect() async throws -> StatsSnapshot {
        var metrics: [MetricKind: MetricValue] = [:]

        if let cpu = cpuCollector.collectCPUUsage() {
            metrics[.cpuUsage] = cpu
        }
        if let memory = memoryCollector.collectMemoryUsage() {
            metrics[.memoryUsage] = memory
        }
        if let network = networkCollector.collectNetworkThroughput() {
            metrics[.networkThroughput] = network
        }
        if let battery = batteryCollector.collectBatteryStatus() {
            metrics[.batteryStatus] = battery
        }
        if let disk = diskCollector.collectDiskUsage() {
            metrics[.diskUsage] = disk
        }

        return StatsSnapshot(
            timestamp: Date(),
            metrics: metrics,
            processCPUUsages: processCPUCollector.collectProcessCPUUsages()
        )
    }
}
