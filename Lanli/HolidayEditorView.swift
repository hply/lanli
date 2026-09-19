import SwiftUI

struct HolidayEditorView: View {
    @EnvironmentObject private var store: AppState
    @State private var formDate = Date()
    @State private var formName = ""
    @State private var formKind = "rest"

    private var yearRows: [HolidayRecord] {
        store.holidays.filter { $0.date.hasPrefix("\(store.viewYear)-") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.system(size: 20, weight: .semibold))

            Toggle("开机时启动", isOn: Binding(
                get: { store.launchAtLogin },
                set: { store.setLaunchAtLogin($0) }
            ))

            Picker("状态栏格式", selection: Binding(
                get: { store.menuFormat },
                set: { store.setMenuFormat($0) }
            )) {
                ForEach(MenuFormat.allCases) { format in
                    Text(format.label).tag(format)
                }
            }
            .pickerStyle(.menu)

            Divider()

            Text("节假日维护")
                .font(.system(size: 16, weight: .semibold))
            Text("\(store.viewYear) 年国务院放假调休可在此增改。节日名会显示在月历格子里，休/班决定调休日。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("日期").font(.caption).foregroundStyle(.secondary)
                    DatePicker("", selection: $formDate, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.timeZone, TimeZone(identifier: "Asia/Shanghai")!)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("名称").font(.caption).foregroundStyle(.secondary)
                    TextField("中秋、调休上班…", text: $formName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("类型").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $formKind) {
                        Text("休").tag("rest")
                        Text("班").tag("work")
                        Text("节日").tag("festival")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
            }

            List {
                ForEach(yearRows) { row in
                    HStack {
                        Text(String(row.date.dropFirst(5)))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 52, alignment: .leading)
                        Text(row.kind == "rest" ? "休" : row.kind == "work" ? "班" : "节")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 18)
                            .background(row.kind == "rest" ? LanliTheme.rest : row.kind == "work" ? LanliTheme.workTag : LanliTheme.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        Text(row.name)
                        Spacer()
                        Text(row.source == "official" ? "官方" : "自订")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(role: .destructive) {
                            store.deleteHoliday(row)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding(20)
        .onAppear {
            formDate = date(from: store.selectedIso) ?? Date()
        }
    }

    private func save() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .gmt
        let y = cal.component(.year, from: formDate)
        let m = cal.component(.month, from: formDate)
        let d = cal.component(.day, from: formDate)
        let name = formName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.upsertHoliday(HolidayRecord(
            date: ISODate.iso(y, m, d),
            name: name.isEmpty ? (formKind == "work" ? "调休上班" : "自定义") : String(name.prefix(12)),
            kind: formKind,
            showLabel: formKind != "work",
            source: "custom"
        ))
        formName = ""
    }

    private func date(from iso: String) -> Date? {
        let p = ISODate.parse(iso)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .gmt
        return cal.date(from: DateComponents(year: p.year, month: p.month, day: p.day))
    }
}
