import Foundation

final class HolidayStore {
    private let customKey = "lanli.customHolidays"
    private let official: [HolidayRecord]

    init() {
        if
            let url = Bundle.main.url(forResource: "Holidays", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let rows = try? JSONDecoder().decode([HolidayRecord].self, from: data)
        {
            official = rows
        } else {
            official = []
        }
    }

    func load() -> [HolidayRecord] {
        merge(custom: readCustom())
    }

    func upsert(_ record: HolidayRecord) -> [HolidayRecord] {
        var custom = readCustom().filter { $0.date != record.date }
        var next = record
        next.source = "custom"
        custom.append(next)
        writeCustom(custom)
        return merge(custom: custom)
    }

    func delete(_ record: HolidayRecord) -> [HolidayRecord] {
        var custom = readCustom().filter { $0.date != record.date }
        if record.source == "official" {
            custom.append(HolidayRecord(
                date: record.date, name: record.name, kind: "festival",
                showLabel: false, source: "custom"
            ))
        }
        writeCustom(custom)
        return merge(custom: custom)
    }

    private func merge(custom: [HolidayRecord]) -> [HolidayRecord] {
        var map = Dictionary(uniqueKeysWithValues: official.map { ($0.date, $0) })
        for row in custom {
            if row.kind == "festival" && row.showLabel == false && official.contains(where: { $0.date == row.date }) {
                map.removeValue(forKey: row.date)
            } else {
                map[row.date] = row
            }
        }
        return map.values.sorted { $0.date < $1.date }
    }

    private func readCustom() -> [HolidayRecord] {
        guard let data = UserDefaults.standard.data(forKey: customKey) else { return [] }
        return (try? JSONDecoder().decode([HolidayRecord].self, from: data)) ?? []
    }

    private func writeCustom(_ rows: [HolidayRecord]) {
        if let data = try? JSONEncoder().encode(rows) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
    }
}
