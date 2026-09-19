import Foundation

/// 公历 1900-01-31 … 2100-12-31 农历、节气、干支、传统节日。
enum Lunar {
    static let monthNames = ["", "正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    static let dayNames = [
        "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    static let gan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    static let zhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    static let shengxiao = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    static let solarTerms = [
        "小寒", "大寒", "立春", "雨水", "惊蛰", "春分",
        "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
        "小暑", "大暑", "立秋", "处暑", "白露", "秋分",
        "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"
    ]

    static func day(year: Int, month: Int, day: Int) -> AlmanacDay {
        let lunar = solarToLunar(year, month, day)
        let iso = String(format: "%04d-%02d-%02d", year, month, day)
        let term = jieqi[year]?[iso] ?? ""
        let festival = festivalName(solarYear: year, solarMonth: month, solarDay: day, lunar: lunar)
        let gzIndex = lunar.year - 4
        let ganzhi = gan[((gzIndex % 10) + 10) % 10] + zhi[((gzIndex % 12) + 12) % 12]
        let animal = shengxiao[((gzIndex % 12) + 12) % 12]
        let monthName = monthNames[safe: lunar.month] ?? "—"
        let dayName = dayNames[safe: lunar.day] ?? "—"
        let caption: String
        if lunar.day == 1 {
            let prefix = lunar.isLeap ? "闰" : ""
            switch monthName {
            case "正": caption = prefix + "正月"
            case "冬": caption = prefix + "冬月"
            case "腊": caption = prefix + "腊月"
            default: caption = prefix + monthName + "月"
            }
        } else {
            caption = dayName
        }
        return AlmanacDay(m: monthName, d: dayName, c: caption, g: ganzhi, s: animal, q: term, f: festival, y: "", j: "")
    }

    struct LunarDate {
        var year: Int
        var month: Int
        var day: Int
        var isLeap: Bool
    }

    static func solarToLunar(_ y: Int, _ m: Int, _ d: Int) -> LunarDate {
        let utc = TimeZone(secondsFromGMT: 0)!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        let target = cal.date(from: DateComponents(year: y, month: m, day: d))!
        let base = cal.date(from: DateComponents(year: 1900, month: 1, day: 31))!
        var offset = cal.dateComponents([.day], from: base, to: target).day ?? 0
        var iyear = 1900
        while iyear <= 2100 {
            let temp = yearDays(iyear)
            if offset < temp { break }
            offset -= temp
            iyear += 1
        }
        let leap = leapMonth(iyear)
        var isLeap = false
        var imonth = 1
        while imonth < 13 {
            let temp: Int
            if leap > 0 && imonth == leap + 1 && !isLeap {
                isLeap = true
                imonth -= 1
                temp = leapDays(iyear)
            } else {
                temp = monthDays(iyear, imonth)
            }
            if isLeap && imonth == leap + 1 {
                isLeap = false
            }
            if offset < temp { break }
            offset -= temp
            imonth += 1
        }
        return LunarDate(year: iyear, month: imonth, day: offset + 1, isLeap: isLeap && imonth == leap)
    }

    private static func leapMonth(_ y: Int) -> Int { lunarInfo[y - 1900] & 0xF }
    private static func leapDays(_ y: Int) -> Int {
        guard leapMonth(y) > 0 else { return 0 }
        return lunarInfo[y - 1900] & 0x10000 != 0 ? 30 : 29
    }
    private static func monthDays(_ y: Int, _ m: Int) -> Int {
        lunarInfo[y - 1900] & (0x10000 >> m) != 0 ? 30 : 29
    }
    private static func yearDays(_ y: Int) -> Int {
        var sum = 348
        var bit = 0x8000
        while bit > 0x8 {
            if lunarInfo[y - 1900] & bit != 0 { sum += 1 }
            bit >>= 1
        }
        return sum + leapDays(y)
    }

    private static let jieqi: [Int: [String: String]] = {
        var map: [Int: [String: String]] = [:]
        let info: [Double] = [
            0, 21208, 42467, 63836, 85337, 107014, 128867, 150921,
            173149, 195551, 218072, 240693, 263343, 285989, 308563, 331033,
            353350, 375494, 397447, 419210, 440795, 462224, 483532, 504758
        ]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let epoch = cal.date(from: DateComponents(year: 1900, month: 1, day: 6, hour: 2, minute: 5))!
        for year in 1900...2100 {
            var yearMap: [String: String] = [:]
            for n in 0..<24 {
                let ms = 31556925974.7 * Double(year - 1900) + info[n] * 60000
                let date = epoch.addingTimeInterval(ms / 1000)
                let y = cal.component(.year, from: date)
                let m = cal.component(.month, from: date)
                let d = cal.component(.day, from: date)
                if y == year {
                    yearMap[String(format: "%04d-%02d-%02d", y, m, d)] = solarTerms[n]
                }
            }
            map[year] = yearMap
        }
        return map
    }()

    private static func festivalName(solarYear: Int, solarMonth: Int, solarDay: Int, lunar: LunarDate) -> String {
        switch (solarMonth, solarDay) {
        case (1, 1): return "元旦"
        case (2, 14): return "情人节"
        case (3, 8): return "妇女节"
        case (3, 12): return "植树节"
        case (4, 1): return "愚人节"
        case (5, 1): return "劳动节"
        case (5, 4): return "青年节"
        case (6, 1): return "儿童节"
        case (7, 1): return "建党节"
        case (8, 1): return "建军节"
        case (9, 10): return "教师节"
        case (10, 1): return "国庆节"
        case (12, 24): return "平安夜"
        case (12, 25): return "圣诞节"
        default: break
        }
        if !lunar.isLeap {
            switch (lunar.month, lunar.day) {
            case (1, 1): return "春节"
            case (1, 15): return "元宵"
            case (2, 2): return "龙头节"
            case (5, 5): return "端午"
            case (7, 7): return "七夕"
            case (7, 15): return "中元"
            case (8, 15): return "中秋"
            case (9, 9): return "重阳"
            case (12, 8): return "腊八"
            default: break
            }
        }
        if lunar.month == 12 {
            let tomorrow = offsetDay(year: solarYear, month: solarMonth, day: solarDay, by: 1)
            let t = solarToLunar(tomorrow.year, tomorrow.month, tomorrow.day)
            if t.month == 1 && t.day == 1 && !t.isLeap { return "除夕" }
        }
        return ""
    }

    private static func offsetDay(year: Int, month: Int, day: Int, by: Int) -> (year: Int, month: Int, day: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
        let next = cal.date(byAdding: .day, value: by, to: date)!
        return (
            cal.component(.year, from: next),
            cal.component(.month, from: next),
            cal.component(.day, from: next)
        )
    }

    /// 农历 1900–2100 闰月与大小月编码（源自通用农历表）。
    private static let lunarInfo: [Int] = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
        0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
        0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
        0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
        0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
        0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
        0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
        0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0,
        0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
        0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
        0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
        0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
        0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
        0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
        0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
        0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
        0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
        0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
        0x0d520
    ]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
