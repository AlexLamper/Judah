import SwiftUI
import WidgetKit

// Mirrors lib/domain/judah_state.dart so the widget stays right while the app
// is closed. The app stores the verses for the coming days and one picture of
// Judah per mood and time of day in the shared App Group.

private let appGroup = "group.com.getjudah.app"

struct JudahEntry: TimelineEntry {
    let date: Date
    let isPro: Bool
    let verseRef: String
    let verseText: String
    let image: UIImage?
    let streak: Int
}

struct JudahProvider: TimelineProvider {
    func placeholder(in context: Context) -> JudahEntry {
        JudahEntry(date: Date(), isPro: true, verseRef: "Psalm 119:105",
                   verseText: "Thy word is a lamp unto my feet, and a light unto my path.",
                   image: nil, streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (JudahEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JudahEntry>) -> Void) {
        // One entry per hour for a day: the scene, mood and verse follow the clock.
        let cal = Calendar.current
        let start = cal.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let entries = (0..<24).compactMap { h in
            cal.date(byAdding: .hour, value: h, to: start).map { entry(at: max($0, Date())) }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> JudahEntry {
        let d = UserDefaults(suiteName: appGroup)
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let scene: String
        switch hour {
        case 5..<11: scene = "morning"
        case 11..<17: scene = "day"
        case 17..<22: scene = "evening"
        default: scene = "night"
        }
        let today = dayKey(date)
        let lastActive = d?.string(forKey: "lastActive") ?? ""
        let missing = !lastActive.isEmpty && (daysBetween(lastActive, today) ?? 0) >= 2
        let mood = scene == "night" ? "sleepy" : (missing ? "sad" : "happy")

        var ref = "Psalm 119:105"
        var text = "Thy word is a lamp unto my feet, and a light unto my path."
        if let raw = d?.string(forKey: "verses"),
           let json = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: [String: String]] {
            // Today's verse, or the newest one stored if the app was not opened for weeks.
            let key = json[today] != nil ? today : json.keys.filter { $0 <= today }.max()
            if let key, let v = json[key], let r = v["ref"], let t = v["text"] {
                ref = r
                text = t
            }
        }

        let streakDay = d?.string(forKey: "streakDay") ?? ""
        let alive = !streakDay.isEmpty && (daysBetween(streakDay, today) ?? 99) <= 1
        let streak = alive ? d?.integer(forKey: "streak") ?? 0 : 0

        let image = (d?.string(forKey: "img_\(mood)_\(scene)")).flatMap { UIImage(contentsOfFile: $0) }
        return JudahEntry(date: date, isPro: d?.bool(forKey: "pro") ?? false,
                          verseRef: ref, verseText: text, image: image, streak: streak)
    }

    private func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func daysBetween(_ from: String, _ to: String) -> Int? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        guard let a = f.date(from: from), let b = f.date(from: to) else { return nil }
        return Calendar(identifier: .gregorian).dateComponents([.day], from: a, to: b).day
    }
}

private let ink = Color(red: 0.23, green: 0.16, blue: 0.12)
private let gold = Color(red: 0.79, green: 0.49, blue: 0.08)
private let sand = Color(red: 1.0, green: 0.97, blue: 0.93)

struct JudahWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: JudahEntry

    private var text: String {
        entry.isPro ? entry.verseText : "Unlock Judah Pro to bring your daily verse here."
    }
    private var ref: String { entry.isPro ? entry.verseRef : "Tap to open Judah" }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.isPro ? "\(entry.verseRef) 🦁" : "Judah")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.isPro ? entry.verseText : "Unlock Judah Pro")
                    .font(.system(size: 13, weight: .semibold)).lineLimit(3)
                Text(ref).font(.system(size: 11, weight: .bold)).opacity(0.8)
            }
        case .systemSmall:
            VStack(spacing: 0) {
                judah
                Text(ref).font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(gold).lineLimit(1).padding(6)
            }
        case .systemLarge:
            VStack(alignment: .leading, spacing: 0) {
                judah
                VStack(alignment: .leading, spacing: 6) {
                    Text(text).font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(ink).lineLimit(5)
                    Text(ref).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(gold)
                    if entry.isPro {
                        Text(entry.streak > 0 ? "🔥 \(entry.streak) day streak" : "Read today's verse to start a streak")
                            .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.secondary)
                    }
                }.padding(14)
            }
        default: // systemMedium
            HStack(spacing: 0) {
                judah.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 6) {
                    Text(text).font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ink).lineLimit(6).minimumScaleFactor(0.8)
                    Text(ref).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(gold)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var judah: some View {
        if let img = entry.image {
            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
        } else {
            Text("🦁").font(.system(size: 48)).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@main
struct JudahWidget: Widget {
    // Must match WidgetSync.iOSKind in lib/services/widget_sync.dart.
    let kind = "JudahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JudahProvider()) { entry in
            JudahWidgetView(entry: entry)
                .containerBackground(for: .widget) { sand }
        }
        .configurationDisplayName("Judah")
        .description("Today's verse with Judah.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}
