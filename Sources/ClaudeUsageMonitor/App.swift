import SwiftUI

@main
struct ClaudeUsageMonitorApp: App {
    @StateObject private var limits = LimitsStore()
    @StateObject private var store = UsageStore()
    // Official /usage is a bit heavy (spawns the CLI) → refresh every 5 min.
    private let slow = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    // Local log cost is cheap → refresh every 60s.
    private let fast = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            DashboardView(limits: limits, store: store)
        } label: {
            MenuBarLabel(limits: limits)
                .onAppear { limits.refresh(); store.refresh() }
                .onReceive(slow) { _ in limits.refresh() }
                .onReceive(fast) { _ in store.refresh() }
        }
        .menuBarExtraStyle(.window)
    }
}

/// The compact text shown in the macOS menu bar: peak limit usage %.
struct MenuBarLabel: View {
    @ObservedObject var limits: LimitsStore

    var body: some View {
        let pct = limits.report?.peakPercent
        HStack(spacing: 3) {
            Image(systemName: symbol(pct))
            Text(pct.map { "\($0)%" } ?? "—")
        }
    }

    private func symbol(_ pct: Int?) -> String {
        guard let p = pct else { return "gauge.with.dots.needle.bottom.50percent" }
        if p >= 80 { return "gauge.with.dots.needle.100percent" }
        if p >= 50 { return "gauge.with.dots.needle.67percent" }
        return "gauge.with.dots.needle.33percent"
    }
}
