import Foundation
import Combine

/// Raw token counts for a record or an aggregate.
struct TokenCounts {
    var input: Double = 0
    var output: Double = 0
    var cacheWrite5m: Double = 0
    var cacheWrite1h: Double = 0
    var cacheRead: Double = 0

    /// Tokens that actually count against "context / throughput" usage.
    var total: Double { input + output + cacheWrite5m + cacheWrite1h + cacheRead }

    static func + (a: TokenCounts, b: TokenCounts) -> TokenCounts {
        TokenCounts(input: a.input + b.input,
                    output: a.output + b.output,
                    cacheWrite5m: a.cacheWrite5m + b.cacheWrite5m,
                    cacheWrite1h: a.cacheWrite1h + b.cacheWrite1h,
                    cacheRead: a.cacheRead + b.cacheRead)
    }

    static func += (a: inout TokenCounts, b: TokenCounts) { a = a + b }
}

/// One assistant turn's usage.
struct UsageRecord {
    let date: Date
    let model: String
    let counts: TokenCounts
    var cost: Double { Pricing.cost(model: model, usage: counts) }
}

/// An aggregate bucket (a day, a model, a 5-hour block…).
struct Bucket: Identifiable {
    let id: String
    var label: String
    var counts = TokenCounts()
    var cost: Double = 0
    var start: Date? = nil
    var end: Date? = nil

    mutating func add(_ r: UsageRecord) {
        counts += r.counts
        cost += r.cost
    }
}

/// A rolling 5-hour usage block (mirrors Claude's session limit window).
struct SessionBlock: Identifiable {
    let id = UUID()
    var start: Date
    var end: Date            // start + 5h
    var lastActivity: Date
    var counts = TokenCounts()
    var cost: Double = 0
    var isActive: Bool { Date() < end }
}

// MARK: - JSONL decoding (only the fields we need)

private struct Line: Decodable {
    let type: String?
    let timestamp: String?
    let message: Msg?
}
private struct Msg: Decodable {
    let model: String?
    let id: String?
    let usage: Usage?
}
private struct Usage: Decodable {
    let input_tokens: Double?
    let output_tokens: Double?
    let cache_creation_input_tokens: Double?
    let cache_read_input_tokens: Double?
    let cache_creation: CacheCreation?
}
private struct CacheCreation: Decodable {
    let ephemeral_1h_input_tokens: Double?
    let ephemeral_5m_input_tokens: Double?
}

/// Reads and aggregates Claude Code usage from ~/.claude/projects.
@MainActor
final class UsageStore: ObservableObject {
    @Published var records: [UsageRecord] = []
    @Published var lastUpdated: Date? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    private let blockHours: Double = 5

    var projectsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        let dir = projectsDir
        Task.detached(priority: .utility) {
            let result = Self.parse(directory: dir)
            await MainActor.run {
                switch result {
                case .success(let recs):
                    self.records = recs.sorted { $0.date < $1.date }
                    self.error = nil
                case .failure(let e):
                    self.error = e.localizedDescription
                }
                self.lastUpdated = Date()
                self.isLoading = false
            }
        }
    }

    // MARK: Parsing (runs off the main actor)

    nonisolated private static func parse(directory: URL) -> Result<[UsageRecord], Error> {
        let fm = FileManager.default
        guard let files = try? fm.subpathsOfDirectory(atPath: directory.path) else {
            return .success([])
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]

        var records: [UsageRecord] = []
        var seen = Set<String>()   // dedup by message id

        for rel in files where rel.hasSuffix(".jsonl") {
            let url = directory.appendingPathComponent(rel)
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            content.enumerateLines { line, _ in
                // Cheap pre-filter: only assistant turns carry a usage object.
                guard line.contains("\"usage\"") else { return }
                guard let data = line.data(using: .utf8),
                      let parsed = try? JSONDecoder().decode(Line.self, from: data),
                      let msg = parsed.message,
                      let usage = msg.usage,
                      let model = msg.model,
                      model != "<synthetic>",
                      let ts = parsed.timestamp else { return }

                // Dedup identical assistant messages that appear in >1 session file.
                if let mid = msg.id {
                    if seen.contains(mid) { return }
                    seen.insert(mid)
                }

                let date = iso.date(from: ts) ?? isoNoFrac.date(from: ts)
                guard let date else { return }

                let cw1h = usage.cache_creation?.ephemeral_1h_input_tokens ?? 0
                let cw5m = usage.cache_creation?.ephemeral_5m_input_tokens
                    ?? (usage.cache_creation_input_tokens ?? 0)   // fallback when no breakdown
                // If a breakdown exists, don't double count against the flat field.
                let counts = TokenCounts(
                    input: usage.input_tokens ?? 0,
                    output: usage.output_tokens ?? 0,
                    cacheWrite5m: usage.cache_creation == nil ? (usage.cache_creation_input_tokens ?? 0) : cw5m,
                    cacheWrite1h: cw1h,
                    cacheRead: usage.cache_read_input_tokens ?? 0
                )
                records.append(UsageRecord(date: date, model: model, counts: counts))
            }
        }
        return .success(records)
    }

    // MARK: Aggregations

    private var calendar: Calendar { Calendar.current }

    func total(since: Date? = nil) -> Bucket {
        var b = Bucket(id: "total", label: "Total")
        for r in records where since == nil || r.date >= since! { b.add(r) }
        return b
    }

    var today: Bucket {
        total(since: calendar.startOfDay(for: Date()))
    }

    var last7Days: Bucket {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return total(since: start)
    }

    var allTime: Bucket { total() }

    /// Per-day buckets for the last `days` days (oldest first), including empty days.
    func dailyBuckets(days: Int) -> [Bucket] {
        let startDay = calendar.date(byAdding: .day, value: -(days - 1),
                                     to: calendar.startOfDay(for: Date()))!
        var map: [Date: Bucket] = [:]
        let df = DateFormatter(); df.dateFormat = "MMM d"
        for r in records where r.date >= startDay {
            let day = calendar.startOfDay(for: r.date)
            var b = map[day] ?? Bucket(id: ISO8601DateFormatter().string(from: day),
                                       label: df.string(from: day), start: day)
            b.add(r)
            map[day] = b
        }
        var out: [Bucket] = []
        for i in 0..<days {
            let day = calendar.date(byAdding: .day, value: i, to: startDay)!
            out.append(map[day] ?? Bucket(id: "\(i)", label: df.string(from: day),
                                          start: day))
        }
        return out
    }

    /// Per-model buckets over the whole history, richest first.
    func modelBuckets(since: Date? = nil) -> [Bucket] {
        var map: [String: Bucket] = [:]
        for r in records where since == nil || r.date >= since! {
            var b = map[r.model] ?? Bucket(id: r.model, label: prettyModel(r.model))
            b.add(r)
            map[r.model] = b
        }
        return map.values.sorted { $0.cost > $1.cost || ($0.cost == $1.cost && $0.counts.total > $1.counts.total) }
    }

    /// ccusage-style 5-hour blocks: a block starts at the top of the hour of its
    /// first message and closes after 5h or a >5h gap in activity.
    func sessionBlocks() -> [SessionBlock] {
        let sorted = records.sorted { $0.date < $1.date }
        var blocks: [SessionBlock] = []
        for r in sorted {
            if var cur = blocks.last,
               r.date < cur.end,
               r.date.timeIntervalSince(cur.lastActivity) < blockHours * 3600 {
                cur.counts += r.counts
                cur.cost += r.cost
                cur.lastActivity = r.date
                blocks[blocks.count - 1] = cur
            } else {
                let hour = calendar.dateInterval(of: .hour, for: r.date)?.start ?? r.date
                var nb = SessionBlock(start: hour,
                                      end: hour.addingTimeInterval(blockHours * 3600),
                                      lastActivity: r.date)
                nb.counts += r.counts
                nb.cost += r.cost
                blocks.append(nb)
            }
        }
        return blocks
    }

    var currentBlock: SessionBlock? {
        sessionBlocks().last.flatMap { $0.isActive ? $0 : nil }
    }
}

// MARK: - Formatting helpers

func prettyModel(_ id: String) -> String {
    id.replacingOccurrences(of: "claude-", with: "")
      .replacingOccurrences(of: "-", with: " ")
      .capitalized
}

func fmtTokens(_ n: Double) -> String {
    switch n {
    case 1_000_000...: return String(format: "%.2fM", n / 1_000_000)
    case 1_000...:     return String(format: "%.1fK", n / 1_000)
    default:           return String(format: "%.0f", n)
    }
}

func fmtUSD(_ n: Double) -> String {
    n >= 100 ? String(format: "$%.0f", n) : String(format: "$%.2f", n)
}
