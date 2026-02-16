import Foundation

// MARK: - ParsedTask
// Result of parsing a natural-language task string.

struct ParsedTask {
    var title: String
    var dueDate: Date?
    var priority: Priority
    var tagNames: [String]
    var repeatFrequency: RepeatFrequency?
    var isSomeday: Bool
}

// MARK: - NLParserService

final class NLParserService {

    // MARK: - Public API

    /// Parse a raw input string into a `ParsedTask`.
    /// Extracts dates, priorities, tags and repeat rules from the text,
    /// then returns the cleaned title with those tokens removed.
    func parse(_ input: String) -> ParsedTask {
        var text = input
        let lower = text.lowercased()

        let priority = extractPriority(from: lower)
        let repeatFreq = extractRepeat(from: lower)
        let isSomeday = lower.contains("someday") || lower.contains("maybe later")
        let tagNames = extractTags(from: text)
        let dueDate = extractDate(from: text)

        text = cleanTitle(
            text,
            removePriority: priority != .none,
            removeRepeat: repeatFreq != nil,
            removeSomeday: isSomeday,
            tagNames: tagNames,
            dueDate: dueDate
        )

        return ParsedTask(
            title: text,
            dueDate: dueDate,
            priority: priority,
            tagNames: tagNames,
            repeatFrequency: repeatFreq,
            isSomeday: isSomeday
        )
    }

    // MARK: - Priority

    private func extractPriority(from lower: String) -> Priority {
        if lower.contains("!!!")  || lower.contains("!high") || lower.contains("#p1") ||
           lower.contains("#high") { return .high }
        if lower.contains("!!")   || lower.contains("!med")  || lower.contains("#p2") ||
           lower.contains("#medium") { return .medium }
        if lower.contains("!")    || lower.contains("!low")  || lower.contains("#p3") ||
           lower.contains("#low") { return .low }
        return .none
    }

    // MARK: - Repeat

    private func extractRepeat(from lower: String) -> RepeatFrequency? {
        if lower.contains("every day") || lower.contains("daily") { return .daily }
        if lower.contains("every week") || lower.contains("weekly") { return .weekly }
        if lower.contains("every month") || lower.contains("monthly") { return .monthly }
        if lower.contains("every year") || lower.contains("yearly") || lower.contains("annually") { return .yearly }
        return nil
    }

    // MARK: - Tags

    /// Extracts tokens of the form `#word` (excluding priority shortcuts).
    private func extractTags(from text: String) -> [String] {
        let priorityTags = ["#p1", "#p2", "#p3", "#high", "#medium", "#low"]
        let pattern = #"#(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match -> String? in
            let full = nsText.substring(with: match.range).lowercased()
            guard !priorityTags.contains(full) else { return nil }
            let inner = nsText.substring(with: match.range(at: 1))
            return inner
        }
    }

    // MARK: - Date

    private func extractDate(from text: String) -> Date? {
        let lower = text.lowercased()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Simple keyword matches first (NSDataDetector misses these)
        if lower.contains("today") { return today }
        if lower.contains("tomorrow") { return cal.date(byAdding: .day, value: 1, to: today) }
        if lower.contains("day after tomorrow") { return cal.date(byAdding: .day, value: 2, to: today) }
        if lower.contains("next week") { return cal.date(byAdding: .weekOfYear, value: 1, to: today) }
        if lower.contains("next month") { return cal.date(byAdding: .month, value: 1, to: today) }
        if lower.contains("this weekend") {
            let weekday = cal.component(.weekday, from: today)
            let daysToSat = (7 - weekday + 7) % 7
            return cal.date(byAdding: .day, value: daysToSat == 0 ? 7 : daysToSat, to: today)
        }

        // Named weekdays: "monday", "next friday" etc.
        let weekdays = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]
        for (idx, name) in weekdays.enumerated() {
            if lower.contains(name) {
                let current = cal.component(.weekday, from: today) - 1  // 0=Sun
                var diff = idx - current
                if diff <= 0 { diff += 7 }
                return cal.date(byAdding: .day, value: diff, to: today)
            }
        }

        // Fall back to NSDataDetector for absolute dates/times ("Jan 15", "5pm", etc.)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        if let match = detector?.firstMatch(in: text, options: [], range: range) {
            return match.date
        }

        return nil
    }

    // MARK: - Title Cleanup

    private func cleanTitle(
        _ text: String,
        removePriority: Bool,
        removeRepeat: Bool,
        removeSomeday: Bool,
        tagNames: [String],
        dueDate: Date?
    ) -> String {
        var result = text

        // Remove #tag tokens (all of them)
        result = result.replacingOccurrences(of: #"#\w+"#, with: "", options: .regularExpression)

        // Remove priority shorthand (!, !!, !!!)
        result = result.replacingOccurrences(of: #"!!!|!!|!"#, with: "", options: .regularExpression)

        // Remove date keywords when a date was extracted
        if dueDate != nil {
            let dateKeywords = [
                "day after tomorrow", "this weekend", "next week", "next month",
                "today", "tomorrow",
                "sunday","monday","tuesday","wednesday","thursday","friday","saturday"
            ]
            for kw in dateKeywords {
                result = result.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
            }
        }

        // Remove repeat keywords
        if removeRepeat {
            let repeatKeywords = [
                "every day","every week","every month","every year",
                "daily","weekly","monthly","yearly","annually"
            ]
            for kw in repeatKeywords {
                result = result.replacingOccurrences(of: kw, with: "", options: .caseInsensitive)
            }
        }

        // Remove someday
        if removeSomeday {
            result = result.replacingOccurrences(of: "maybe later", with: "", options: .caseInsensitive)
            result = result.replacingOccurrences(of: "someday", with: "", options: .caseInsensitive)
        }

        // Collapse extra whitespace and trim
        result = result.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
