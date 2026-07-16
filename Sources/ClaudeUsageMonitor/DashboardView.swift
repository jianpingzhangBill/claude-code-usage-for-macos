import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var limits: LimitsStore
    @ObservedObject var store: UsageStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let r = limits.report {
                    limitsSection(r)
                    activitySection(r)
                    contributorsSection(r)
                } else if limits.isLoading {
                    loading
                } else if let e = limits.error {
                    errorBox(e)
                }

                Divider()
                localCostSection

                Divider()
                footer
            }
            .padding(16)
        }
        .frame(width: 400, height: 620)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Image(systemName: "gauge.with.dots.needle.67percent").foregroundStyle(.tint)
            Text("Claude Usage").font(.headline)
            Spacer()
            if limits.isLoading || store.isLoading { ProgressView().controlSize(.small) }
            Button { limits.refresh(); store.refresh() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("刷新")
        }
    }

    private var loading: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("正在读取官方用量 (claude /usage)…").foregroundStyle(.secondary)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
    }

    private func errorBox(_ e: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("无法获取官方用量", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            Text(e).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            Text("需要能在登录 shell 里运行 `claude -p '/usage'`。")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Official limits

    private func limitsSection(_ r: UsageReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle("用量限额 · 官方")
                Spacer()
                Text("subscription").font(.caption2).foregroundStyle(.tertiary)
            }
            ForEach(r.limits) { bar in LimitRow(bar: bar) }
        }
    }

    // MARK: Activity windows

    private func activitySection(_ r: UsageReport) -> some View {
        HStack(spacing: 10) {
            ForEach(r.windows) { w in
                VStack(alignment: .leading, spacing: 3) {
                    Text(w.label).font(.caption2).foregroundStyle(.secondary)
                    Text("\(w.requests)").font(.title3.bold())
                    Text("requests").font(.caption2).foregroundStyle(.secondary)
                    Text("\(w.sessions) sessions").font(.caption2).foregroundStyle(.secondary)
                    if let ctx = w.notes.first(where: { $0.contains("context") }) {
                        Text(shorten(ctx)).font(.caption2).foregroundStyle(.tertiary).lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func shorten(_ s: String) -> String {
        s.replacingOccurrences(of: "of your usage was at", with: "@")
         .replacingOccurrences(of: " context", with: " ctx")
    }

    // MARK: Top contributors (from the 7d window)

    @ViewBuilder
    private func contributorsSection(_ r: UsageReport) -> some View {
        if let w = r.windows.last, !w.tops.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                SectionTitle("主要来源 · \(w.label)")
                ForEach(Array(w.tops.enumerated()), id: \.offset) { _, top in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(top.0.capitalized).font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(top.1).font(.caption).foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: Local estimated cost (JSONL — the one thing /usage doesn't give)

    private var localCostSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionTitle("花费估算 · 本地日志")
                Spacer()
                Text("按公开单价估算").font(.caption2).foregroundStyle(.tertiary)
            }
            HStack(spacing: 10) {
                CostCard(title: "今日", bucket: store.today, accent: .accentColor)
                CostCard(title: "近 7 天", bucket: store.last7Days, accent: .teal)
                CostCard(title: "全部", bucket: store.allTime, accent: .purple)
            }
            DailyChart(buckets: store.dailyBuckets(days: 14))
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if let t = limits.lastUpdated {
                Text("更新于 \(t, style: .time)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("退出") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless).font(.caption)
        }
    }
}

// MARK: - Components

private struct SectionTitle: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text).font(.subheadline.bold()).foregroundStyle(.secondary) }
}

private struct LimitRow: View {
    let bar: LimitBar
    private var color: Color { bar.percent >= 80 ? .red : (bar.percent >= 50 ? .orange : .green) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(bar.name).font(.callout)
                Spacer()
                Text("\(bar.percent)%").font(.callout.bold().monospacedDigit()).foregroundStyle(color)
            }
            ProgressView(value: Double(bar.percent), total: 100).tint(color)
            Text("resets \(bar.resets)").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct CostCard: View {
    let title: String
    let bucket: Bucket
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(fmtUSD(bucket.cost)).font(.title3.bold()).foregroundStyle(accent)
            Text("\(fmtTokens(bucket.counts.total)) tok").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DailyChart: View {
    let buckets: [Bucket]
    var body: some View {
        if buckets.allSatisfy({ $0.cost == 0 }) {
            Text("暂无花费记录").font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            Chart(buckets) { b in
                BarMark(x: .value("Day", b.label), y: .value("Cost", b.cost))
                    .foregroundStyle(.tint).cornerRadius(2)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) { _ in AxisValueLabel().font(.caption2) } }
            .chartYAxis { AxisMarks(position: .leading) { AxisValueLabel().font(.caption2) } }
            .frame(height: 90)
        }
    }
}
