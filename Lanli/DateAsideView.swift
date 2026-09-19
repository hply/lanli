import SwiftUI

struct DateAsideView: View {
    let clock: ChinaStamp
    let day: DayCell
    let location: String
    let cities: [String]
    let holidays: [HolidayRecord]
    let onLocation: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(clock.hhmm)
                .font(.system(size: 28, weight: .medium).monospacedDigit())
                .padding(.top, 16)
            Text(ChinaStamp.weekdayNames[day.weekday])
                .font(.system(size: 13))
                .padding(.top, 4)

            Text("\(day.day)")
                .font(.system(size: 56, weight: .medium).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(LanliTheme.today)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.top, 16)

            Text(headline)
                .font(.system(size: 12))
                .opacity(0.9)
                .padding(.top, 10)
                .multilineTextAlignment(.center)

            if !day.yi.isEmpty {
                Text("宜 \(day.yi)")
                    .font(.system(size: 12))
                    .opacity(0.86)
                    .padding(.top, 6)
            }

            Spacer(minLength: 12)

            VStack(spacing: 4) {
                Text("\(day.ganzhiYear)年【\(day.shengxiao)年】")
                Text(day.lunarFull)
            }
            .font(.system(size: 13))
            .padding(.bottom, 8)

            Picker("所在城市", selection: Binding(get: { location }, set: onLocation)) {
                ForEach(cities, id: \.self) { city in
                    Text(city).tag(city)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .labelsHidden()
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [LanliTheme.blue, LanliTheme.blueDeep], startPoint: .top, endPoint: .bottom)
        )
    }

    private var headline: String {
        if day.rest {
            return day.festivalLine.map { "\($0)假期" } ?? "假期中"
        }
        if day.work { return "调休上班" }
        let next = holidays
            .filter { $0.isRest && $0.showLabel && $0.date >= day.iso }
            .sorted { $0.date < $1.date }
            .first
        guard let next else { return "暂无假期数据" }
        let days = ISODate.diffDays(day.iso, next.date)
        if days == 0 { return next.name }
        return "距\(next.name) \(days) 天"
    }
}

private extension ISODate {
    static func diffDays(_ from: String, _ to: String) -> Int {
        let a = parse(from)
        let b = parse(to)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let da = cal.date(from: DateComponents(year: a.year, month: a.month, day: a.day))!
        let db = cal.date(from: DateComponents(year: b.year, month: b.month, day: b.day))!
        return cal.dateComponents([.day], from: da, to: db).day ?? 0
    }
}
