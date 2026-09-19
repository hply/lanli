import SwiftUI

struct MonthGridView: View {
    let cells: [DayCell]
    let selectedIso: String
    let onSelect: (String) -> Void

    private let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(index == 0 || index == 6 ? LanliTheme.rest : Color.gray)
                        .frame(height: 30)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(cells) { cell in
                    DayCellView(cell: cell, selected: cell.iso == selectedIso)
                        .onTapGesture { onSelect(cell.iso) }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
        .padding(.top, 4)
    }
}

private struct DayCellView: View {
    let cell: DayCell
    let selected: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(fill)
            if selected && !cell.isToday {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(LanliTheme.today, lineWidth: 2)
            }
            VStack(spacing: 3) {
                Text("\(cell.day)")
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundStyle(numberColor)
                Text(cell.festivalLine ?? cell.lunarLine)
                    .font(.system(size: 11))
                    .foregroundStyle(subColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if cell.rest {
                tag("休", LanliTheme.rest)
            } else if cell.work {
                tag("班", LanliTheme.workTag)
            }
        }
        .frame(height: 62)
        .contentShape(Rectangle())
    }

    private var fill: Color {
        if cell.isToday { return LanliTheme.today }
        if cell.rest { return LanliTheme.restBg }
        if cell.work { return LanliTheme.workBg }
        return .clear
    }

    private var numberColor: Color {
        if cell.isToday { return Color(red: 0.165, green: 0.102, blue: 0) }
        if !cell.inMonth && !cell.rest { return Color(white: 0.75) }
        if cell.rest || (cell.isWeekend && cell.inMonth) { return LanliTheme.rest }
        return LanliTheme.ink
    }

    private var subColor: Color {
        if cell.isToday { return Color(red: 0.353, green: 0.227, blue: 0) }
        if cell.festivalLine != nil { return LanliTheme.rest }
        if !cell.inMonth { return Color(white: 0.78) }
        return LanliTheme.lunar
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 16, height: 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .padding(3)
    }
}
