import Foundation

struct HolidayRecord: Codable, Identifiable, Hashable {
    var date: String
    var name: String
    var kind: String
    var showLabel: Bool
    var source: String

    var id: String { date }

    var isRest: Bool { kind == "rest" }
    var isWork: Bool { kind == "work" }
}

struct AlmanacDay: Codable {
    var m: String
    var d: String
    var c: String
    var g: String
    var s: String
    var q: String
    var f: String
    var y: String
    var j: String

    var lunarFull: String { "\(m)月\(d)" }
    var caption: String? {
        if !f.isEmpty { return f }
        if !q.isEmpty { return q }
        return nil
    }
}

struct DayCell: Identifiable, Hashable {
    var iso: String
    var year: Int
    var month: Int
    var day: Int
    var inMonth: Bool
    var isToday: Bool
    var isWeekend: Bool
    var weekday: Int
    var lunarLine: String
    var festivalLine: String?
    var ganzhiYear: String
    var shengxiao: String
    var lunarFull: String
    var yi: String
    var ji: String
    var rest: Bool
    var work: Bool
    var holidayName: String?

    var id: String { iso }
}

enum ISODate {
    static func iso(_ y: Int, _ m: Int, _ d: Int) -> String {
        String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func parse(_ iso: String) -> (year: Int, month: Int, day: Int) {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        return (p[safe: 0] ?? 2026, p[safe: 1] ?? 1, p[safe: 2] ?? 1)
    }

    static func daysInMonth(_ y: Int, _ m: Int) -> Int {
        var c = DateComponents()
        c.calendar = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")
        c.year = y
        c.month = m
        c.day = 1
        return c.calendar!.range(of: .day, in: .month, for: c.date!)!.count
    }

    static func weekday(_ y: Int, _ m: Int, _ d: Int) -> Int {
        var c = DateComponents()
        let cal = Calendar(identifier: .gregorian)
        c.calendar = cal
        c.timeZone = TimeZone(secondsFromGMT: 0)
        c.year = y
        c.month = m
        c.day = d
        return cal.component(.weekday, from: c.date!) - 1
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ChinaStamp {
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
    var weekday: Int
    var iso: String

    var hhmm: String { String(format: "%02d:%02d", hour, minute) }
    var hhmmss: String { String(format: "%02d:%02d:%02d", hour, minute, second) }

    static let weekdayNames = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
    static let weekdayShort = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    static func now(_ date: Date = Date()) -> ChinaStamp {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .gmt
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let h = cal.component(.hour, from: date)
        let min = cal.component(.minute, from: date)
        let sec = cal.component(.second, from: date)
        let w = cal.component(.weekday, from: date) - 1
        return ChinaStamp(
            year: y, month: m, day: d, hour: h, minute: min, second: sec, weekday: w,
            iso: ISODate.iso(y, m, d)
        )
    }
}
