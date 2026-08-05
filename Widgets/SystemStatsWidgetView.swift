import SwiftUI
import Darwin

// MARK: - Sendable Stats Snapshot

/// A Sendable snapshot of system statistics, safe to pass across concurrency domains.
struct SystemStatsSnapshot: Sendable {
    let cpuPercent: Double
    let memoryUsedGB: Double
    let memoryTotalGB: Double
}

// MARK: - Sampler

/// Nonisolated sampler that reads Mach host statistics from the kernel.
/// All Mach API calls happen off the main actor.
struct SystemStatsSampler {

    /// Sample CPU and memory at the current instant.
    /// Returns nil when Mach calls fail.
    static func sample() -> SystemStatsSnapshot? {
        guard let cpu = sampleCPU(), let mem = sampleMemory() else {
            return nil
        }
        return SystemStatsSnapshot(
            cpuPercent: cpu,
            memoryUsedGB: mem.used,
            memoryTotalGB: mem.total
        )
    }

    // MARK: CPU

    // HOST_CPU_LOAD_INFO_COUNT is deprecated on macOS 26; compute manually.
    private static let cpuLoadInfoCount: mach_msg_type_number_t =
        mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    private static func sampleCPU() -> Double? {
        var size = cpuLoadInfoCount
        var info = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let user = Double(info.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3)
        let total = user + system + idle + nice

        guard total > 0 else { return nil }

        // Use stored previous ticks to compute delta
        struct Previous: @unchecked Sendable {
            static let shared = Previous()
            var total: Double = 0
            var idle: Double = 0
        }

        nonisolated(unsafe) var prev = Previous.shared

        let deltaTotal = total - prev.total
        let deltaIdle = idle - prev.idle

        prev.total = total
        prev.idle = idle

        guard deltaTotal > 0 else { return nil }

        return min(max((1.0 - deltaIdle / deltaTotal) * 100.0, 0), 100)
    }

    // MARK: Memory

    // HOST_VM_INFO64_COUNT is deprecated on macOS 26; compute manually.
    private static let vmInfo64Count: mach_msg_type_number_t =
        mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

    private static func sampleMemory() -> (used: Double, total: Double)? {
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        var pageSize: vm_size_t = 0
        let hostPort = mach_host_self()
        host_page_size(hostPort, &pageSize)

        var size = vmInfo64Count
        var vmInfo = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSizeD = Double(pageSize)
        let activePages = Double(vmInfo.active_count)
        let wireCount = Double(vmInfo.wire_count)
        let compressedPages = Double(vmInfo.compressor_page_count)

        let usedBytes = (activePages + wireCount + compressedPages) * pageSizeD
        let totalGB = Double(totalBytes) / 1_073_741_824.0
        let usedGB = usedBytes / 1_073_741_824.0

        return (usedGB, totalGB)
    }
}

// MARK: - Widget View

/// System stats widget — real-time CPU and memory monitoring.
struct SystemStatsWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var snapshot: SystemStatsSnapshot?
    @State private var sampleTask: Task<Void, Never>?

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                EmptyView()
            }

            Divider()

            // Stats
            VStack(spacing: XuloraSpacing.lg) {
                if let snap = snapshot {
                    statRow(
                        icon: "cpu",
                        label: "CPU",
                        percent: snap.cpuPercent,
                        detail: String(format: "%.1f%%", snap.cpuPercent)
                    )
                    statRow(
                        icon: "memorychip",
                        label: "内存",
                        percent: snap.memoryUsedGB / max(snap.memoryTotalGB, 1) * 100.0,
                        detail: String(format: "%.1f / %.1f GB", snap.memoryUsedGB, snap.memoryTotalGB)
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .widgetContentPadding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WidgetBackground(appearance: appearance))
        .task {
            sampleTask = Task {
                await runSampling()
            }
        }
        .onDisappear {
            sampleTask?.cancel()
        }
    }

    // MARK: Subviews

    private func statRow(icon: String, label: String, percent: Double, detail: String) -> some View {
        VStack(spacing: XuloraSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(XuloraTypography.sectionTitle)
                Spacer()
                Text(detail)
                    .font(XuloraTypography.body)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: percent))
                        .frame(width: geo.size.width * CGFloat(min(percent, 100) / 100.0), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func barColor(for percent: Double) -> Color {
        switch percent {
        case 0..<50:  return .green
        case 50..<80: return .orange
        default:      return .red
        }
    }

    private func runSampling() async {
        for await _ in AsyncStream<Void>.periodic(every: 2) {
            guard !Task.isCancelled else { break }

            let result = SystemStatsSampler.sample()
            await MainActor.run {
                self.snapshot = result
            }
        }
    }
}

// MARK: - AsyncStream Periodic

extension AsyncStream where Element == Void {
    static func periodic(every interval: TimeInterval) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    continuation.yield(())
                    try? await Task.sleep(for: .seconds(interval))
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
