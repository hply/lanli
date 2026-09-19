import Combine
import Foundation
import ServiceManagement
import SwiftUI

enum MenuFormat: String, CaseIterable, Identifiable {
    case md, mdw, mdwhm, mdwhms, icon
    var id: String { rawValue }
    var label: String {
        switch self {
        case .md: return "月日"
        case .mdw: return "月日周"
        case .mdwhm: return "月日周时分"
        case .mdwhms: return "月日周时分秒"
        case .icon: return "只显示图标"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var now: ChinaStamp
    @Published var viewYear: Int
    @Published var viewMonth: Int
    @Published var selectedIso: String
    @Published var location: String
    @Published var holidays: [HolidayRecord]
    @Published var settingsOpen = false
    @Published var menuFormat: MenuFormat
    @Published var launchAtLogin: Bool

    private var timer: AnyCancellable?
    private let holidayStore = HolidayStore()
    private let almanac = AlmanacService.shared

    let years = Array(1900...2100)
    let cities = [
        "北京·朝阳", "上海·嘉定", "广州·天河", "深圳·南山", "杭州·西湖",
        "成都·武侯", "武汉·武昌", "西安·雁塔", "南京·鼓楼", "重庆·渝中",
        "苏州·工业园区", "天津·和平", "长沙·岳麓", "郑州·金水"
    ]

    init() {
        let stamp = ChinaStamp.now()
        now = stamp
        viewYear = stamp.year
        viewMonth = stamp.month
        selectedIso = stamp.iso
        location = UserDefaults.standard.string(forKey: "lanli.location") ?? "上海·嘉定"
        holidays = holidayStore.load()
        let stored = UserDefaults.standard.string(forKey: "lanli.menuFormat") ?? "mdwhm"
        menuFormat = MenuFormat(rawValue: stored) ?? .mdwhm
        launchAtLogin = SMAppService.mainApp.status == .enabled
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.now = ChinaStamp.now()
            }
    }

    var menuTitle: String {
        let w = ChinaStamp.weekdayShort[now.weekday]
        let md = "\(now.month)月\(now.day)日"
        let hm = now.hhmm
        let hms = now.hhmmss
        switch menuFormat {
        case .md: return md
        case .mdw: return "\(md) \(w)"
        case .mdwhm: return "\(md) \(w) \(hm)"
        case .mdwhms: return "\(md) \(w) \(hms)"
        case .icon: return ""
        }
    }

    var todayIso: String { now.iso }

    var selected: DayCell {
        let p = ISODate.parse(selectedIso)
        return DayCellBuilder.build(
            year: p.year, month: p.month, day: p.day,
            inMonth: true, todayIso: todayIso,
            holidays: holidayIndex, almanac: almanac
        )
    }

    var cells: [DayCell] {
        DayCellBuilder.month(
            year: viewYear, month: viewMonth,
            todayIso: todayIso, holidays: holidayIndex, almanac: almanac
        )
    }

    private var holidayIndex: [String: HolidayRecord] {
        Dictionary(uniqueKeysWithValues: holidays.map { ($0.date, $0) })
    }

    func goToday() {
        let stamp = ChinaStamp.now()
        viewYear = stamp.year
        viewMonth = stamp.month
        selectedIso = stamp.iso
    }

    func shiftMonth(_ delta: Int) {
        var y = viewYear
        var m = viewMonth + delta
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        y = min(2100, max(1900, y))
        viewYear = y
        viewMonth = m
        let p = ISODate.parse(selectedIso)
        let keep = min(p.day, ISODate.daysInMonth(y, m))
        selectedIso = ISODate.iso(y, m, keep)
    }

    func select(_ iso: String) {
        selectedIso = iso
        let p = ISODate.parse(iso)
        viewYear = p.year
        viewMonth = p.month
    }

    func setYear(_ year: Int) {
        viewYear = year
        let p = ISODate.parse(selectedIso)
        let keep = min(p.day, ISODate.daysInMonth(year, viewMonth))
        selectedIso = ISODate.iso(year, viewMonth, keep)
    }

    func setLocation(_ value: String) {
        location = value
        UserDefaults.standard.set(value, forKey: "lanli.location")
    }

    func setMenuFormat(_ value: MenuFormat) {
        menuFormat = value
        UserDefaults.standard.set(value.rawValue, forKey: "lanli.menuFormat")
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    func upsertHoliday(_ record: HolidayRecord) {
        holidays = holidayStore.upsert(record)
    }

    func deleteHoliday(_ record: HolidayRecord) {
        holidays = holidayStore.delete(record)
    }
}
