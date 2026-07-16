import Foundation

/// Per–million-token prices in USD for one model family.
struct ModelPrice: Codable {
    var input: Double
    var output: Double
    var cacheWrite5m: Double
    var cacheWrite1h: Double
    var cacheRead: Double
}

/// Pricing table keyed by model *family*. Families are matched as substrings of
/// the model id (e.g. "claude-opus-4-8" -> "opus"). Users can override any of
/// these by dropping a JSON file at:
///     ~/.config/claude-usage-monitor/pricing.json
/// with the same shape, e.g. {"fable": {"input": 15, "output": 75, ...}}
enum Pricing {
    // Anthropic list prices (USD / MTok). Adjust via the override file if needed.
    static let defaults: [String: ModelPrice] = [
        "opus":   ModelPrice(input: 15,   output: 75,  cacheWrite5m: 18.75, cacheWrite1h: 30,  cacheRead: 1.5),
        "sonnet": ModelPrice(input: 3,    output: 15,  cacheWrite5m: 3.75,  cacheWrite1h: 6,   cacheRead: 0.30),
        "haiku":  ModelPrice(input: 0.80, output: 4,   cacheWrite5m: 1.0,   cacheWrite1h: 1.6, cacheRead: 0.08),
        // Newer / Mythos-class models: default to Opus-tier pricing until adjusted.
        "fable":  ModelPrice(input: 15,   output: 75,  cacheWrite5m: 18.75, cacheWrite1h: 30,  cacheRead: 1.5),
        "mythos": ModelPrice(input: 15,   output: 75,  cacheWrite5m: 18.75, cacheWrite1h: 30,  cacheRead: 1.5),
    ]

    private static let table: [String: ModelPrice] = {
        var t = defaults
        // Merge user overrides if present.
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent(".config/claude-usage-monitor/pricing.json")
        if let data = try? Data(contentsOf: url),
           let overrides = try? JSONDecoder().decode([String: ModelPrice].self, from: data) {
            for (k, v) in overrides { t[k.lowercased()] = v }
        }
        return t
    }()

    /// Returns the price table for a model id, or nil if the family is unknown
    /// (e.g. non-Anthropic models routed through the CLI).
    static func price(for model: String) -> ModelPrice? {
        let m = model.lowercased()
        for (family, price) in table where m.contains(family) {
            return price
        }
        return nil
    }

    /// Estimated USD cost of a single usage record.
    static func cost(model: String, usage: TokenCounts) -> Double {
        guard let p = price(for: model) else { return 0 }
        let m = 1_000_000.0
        return usage.input       / m * p.input
             + usage.output      / m * p.output
             + usage.cacheWrite5m / m * p.cacheWrite5m
             + usage.cacheWrite1h / m * p.cacheWrite1h
             + usage.cacheRead   / m * p.cacheRead
    }
}
