import SwiftUI

struct CalendarPopupView: View {
    @EnvironmentObject private var store: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                header
                MonthGridView(
                    cells: store.cells,
                    selectedIso: store.selectedIso,
                    onSelect: store.select
                )
            }
            .frame(width: 520)
            .background(Color.white)

            DateAsideView(
                clock: store.now,
                day: store.selected,
                location: store.location,
                cities: store.cities,
                holidays: store.holidays,
                onLocation: store.setLocation
            )
            .frame(width: 168)
        }
        .frame(width: 688, height: 428)
        .background(LanliTheme.blue)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Picker("年份", selection: yearBinding) {
                ForEach(store.years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 88)
            .tint(LanliTheme.ink)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Button { store.shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text(String(format: "%02d-%02d", store.selected.month, store.selected.day))
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .frame(minWidth: 64)

                Button { store.shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)

            Spacer(minLength: 0)

            Button("返回今天") { store.goToday() }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white)
                .foregroundStyle(LanliTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .font(.system(size: 13, weight: .medium))

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .background(.white.opacity(0.16))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .help("节假日维护")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(
            LinearGradient(colors: [LanliTheme.blue, LanliTheme.blueDeep], startPoint: .top, endPoint: .bottom)
        )
    }

    private var yearBinding: Binding<Int> {
        Binding(get: { store.viewYear }, set: { store.setYear($0) })
    }
}
