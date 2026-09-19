import Foundation

final class AlmanacService {
    static let shared = AlmanacService()
    private let overlay: [String: AlmanacDay]

    private init() {
        var merged: [String: AlmanacDay] = [:]
        let decoder = JSONDecoder()
        for year in 1900...2100 {
            guard let url = Bundle.main.url(forResource: "Almanac-\(year)", withExtension: "json") else { continue }
            if let data = try? Data(contentsOf: url),
               let decoded = try? decoder.decode([String: AlmanacDay].self, from: data) {
                merged.merge(decoded) { _, new in new }
            }
        }
        if merged.isEmpty,
           let url = Bundle.main.url(forResource: "Almanac", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([String: AlmanacDay].self, from: data) {
            merged = decoded
        }
        overlay = merged
    }

    func day(_ iso: String) -> AlmanacDay {
        if let hit = overlay[iso] { return hit }
        let p = ISODate.parse(iso)
        guard (1900...2100).contains(p.year) else {
            return AlmanacDay(m: "—", d: "—", c: "—", g: "—", s: "—", q: "", f: "", y: "", j: "")
        }
        return Lunar.day(year: p.year, month: p.month, day: p.day)
    }
}

enum DayCellBuilder {
    static func month(
        year: Int,
        month: Int,
        todayIso: String,
        holidays: [String: HolidayRecord],
        almanac: AlmanacService
    ) -> [DayCell] {
        let firstWeekday = ISODate.weekday(year, month, 1)
        let count = ISODate.daysInMonth(year, month)
        let prevMonth = month == 1 ? 12 : month - 1
        let prevYear = month == 1 ? year - 1 : year
        let prevCount = ISODate.daysInMonth(prevYear, prevMonth)
        var cells: [DayCell] = []
        for i in 0..<42 {
            let offset = i - firstWeekday + 1
            var y = year, m = month, d = offset, inMonth = true
            if offset < 1 {
                y = prevYear; m = prevMonth; d = prevCount + offset; inMonth = false
            } else if offset > count {
                y = month == 12 ? year + 1 : year
                m = month == 12 ? 1 : month + 1
                d = offset - count
                inMonth = false
            }
            cells.append(build(year: y, month: m, day: d, inMonth: inMonth, todayIso: todayIso, holidays: holidays, almanac: almanac))
        }
        return cells
    }

    static func build(
        year: Int,
        month: Int,
        day: Int,
        inMonth: Bool,
        todayIso: String,
        holidays: [String: HolidayRecord],
        almanac: AlmanacService
    ) -> DayCell {
        let iso = ISODate.iso(year, month, day)
        let info = almanac.day(iso)
        let holiday = holidays[iso]
        let dbLabel = (holiday?.showLabel == true && holiday?.kind != "work") ? holiday?.name : nil
        let festival = dbLabel ?? info.caption
        let weekday = ISODate.weekday(year, month, day)
        return DayCell(
            iso: iso,
            year: year,
            month: month,
            day: day,
            inMonth: inMonth,
            isToday: iso == todayIso,
            isWeekend: weekday == 0 || weekday == 6,
            weekday: weekday,
            lunarLine: info.c,
            festivalLine: festival,
            ganzhiYear: info.g,
            shengxiao: info.s,
            lunarFull: info.lunarFull,
            yi: info.y,
            ji: info.j,
            rest: holiday?.isRest == true,
            work: holiday?.isWork == true,
            holidayName: holiday?.name
        )
    }
}
