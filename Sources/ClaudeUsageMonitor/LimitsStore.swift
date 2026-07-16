import Foundation

/// One official limit bar from `claude /usage` (session or weekly).
struct LimitBar: Identifiable {
    let id = UUID()
    let name: String        // "Current session", "Current week (all models)", …
    let percent: Int        // 0–100
    let resets: String      // "Jul 16 at 5:19pm (Asia/Singapore)"
}

/// An activity window ("Last 24h" / "Last 7d") from `claude /usage`.
struct ActivityWindow: Identifiable {
    let id = UUID()
    let label: String       // "Last 24h"
    let requests: Int
    let sessions: Int
    var notes: [String] = []                 // e.g. "81% of your usage was at >150k context"
    var tops: [(String, String)] = []        // ("skills", "/git-build-push 6%, …")
}

/// The parsed official usage report.
struct UsageReport {
    var mode: String = ""
    var limits: [LimitBar] = []
    var windows: [ActivityWindow] = []
    var raw: String = ""

    /// The highest limit percentage — what we surface in the menu bar.
    var peakPercent: Int { limits.map(\.percent).max() ?? 0 }
}

/// Simple error carrying a user-facing message.
struct RunError: Error { let message: String }

/// Runs `claude -p '/usage'` (via a login shell so it inherits the same
/// environment the CLI normally uses) and parses the official output.
@MainActor
final class LimitsStore: ObservableObject {
    @Published var report: UsageReport? = nil
    @Published var lastUpdated: Date? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        Task.detached(priority: .utility) {
            let result = Self.runUsageCommand()
            await MainActor.run {
                switch result {
                case .success(let text):
                    self.report = Self.parse(text)
                    self.error = nil
                case .failure(let e):
                    self.error = e.message
                }
                self.lastUpdated = Date()
                self.isLoading = false
            }
        }
    }

    // MARK: Run the CLI

    nonisolated private static func runUsageCommand() -> Result<String, RunError> {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // A login shell is the only portable way to find `claude` regardless of
        // how it was installed (npm, nvm/fnm, Homebrew, the native installer, …):
        // we resolve it via the user's own PATH rather than guessing paths.
        //
        // `--strict-mcp-config` (with no `--mcp-config`) loads zero MCP servers, so
        // this lightweight usage query never spawns the MCP health-check subprocesses
        // claude would otherwise start. Those child processes are what caused macOS
        // to attribute an unrelated media-library permission prompt to this app; the
        // `/usage` contributor breakdown is computed from local logs, so nothing is
        // lost. We also run from $HOME so no project-local `.mcp.json` is picked up.
        p.arguments = ["-lc", "claude -p '/usage' --strict-mcp-config"]
        p.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let out = Pipe(); let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do { try p.run() } catch {
            return .failure(RunError(message: L("Couldn't launch claude: %@", error.localizedDescription)))
        }
        // Guard against a hung CLI.
        let deadline = DispatchTime.now() + 40
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async { p.waitUntilExit(); group.leave() }
        if group.wait(timeout: deadline) == .timedOut {
            p.terminate()
            return .failure(RunError(message: L("claude /usage timed out (>40s)")))
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // `claude` isn't on the PATH the login shell built — most likely it
            // isn't installed, or lives somewhere the shell profile doesn't export.
            if e.contains("command not found") || e.contains("not found") {
                return .failure(RunError(message: L("Claude Code CLI not found. Install it and make sure `claude` is on your PATH.")))
            }
            return .failure(RunError(message: e.isEmpty ? L("claude /usage produced no output") : e))
        }
        return .success(text)
    }

    // MARK: Parse the text output

    nonisolated private static func parse(_ text: String) -> UsageReport {
        var r = UsageReport(raw: text)
        let lines = text.components(separatedBy: .newlines)
        var currentWindowIndex: Int? = nil

        func firstMatch(_ pattern: String, _ s: String) -> [String]? {
            guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
            let range = NSRange(s.startIndex..., in: s)
            guard let m = re.firstMatch(in: s, range: range) else { return nil }
            var groups: [String] = []
            for i in 0..<m.numberOfRanges {
                if let rr = Range(m.range(at: i), in: s) { groups.append(String(s[rr])) }
                else { groups.append("") }
            }
            return groups
        }

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }

            if t.hasPrefix("You are currently using") {
                r.mode = t
            } else if let g = firstMatch(#"Current session:\s*(\d+)%\s*used.*?resets\s+(.+)"#, t) {
                r.limits.append(LimitBar(name: "Current session", percent: Int(g[1]) ?? 0, resets: g[2]))
            } else if let g = firstMatch(#"Current week\s*\(([^)]+)\):\s*(\d+)%\s*used.*?resets\s+(.+)"#, t) {
                r.limits.append(LimitBar(name: "Current week (\(g[1]))", percent: Int(g[2]) ?? 0, resets: g[3]))
            } else if let g = firstMatch(#"(Last\s+\S+)\s.*?(\d+)\s*requests.*?(\d+)\s*sessions"#, t) {
                r.windows.append(ActivityWindow(label: g[1], requests: Int(g[2]) ?? 0, sessions: Int(g[3]) ?? 0))
                currentWindowIndex = r.windows.count - 1
            } else if let idx = currentWindowIndex {
                if let g = firstMatch(#"Top\s+([\w ]+?):\s*(.+)"#, t) {
                    r.windows[idx].tops.append((g[1], g[2]))
                } else if t.contains("% of your usage") || t.contains("came from") {
                    r.windows[idx].notes.append(t)
                }
            }
        }
        return r
    }
}
