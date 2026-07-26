import SwiftUI

struct CalendarView: View {
    private let days = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Label("우리 가족", systemImage: "person.2.fill")
                        .font(MoilTypography.semibold(15))
                        .foregroundStyle(MoilColor.textPrimary)
                    Spacer()
                    Image(systemName: "bell")
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("7월").font(MoilTypography.bold(32))
                        Text("2026").font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.left")
                    Image(systemName: "chevron.right").padding(.leading, 18)
                }
                .padding(16)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(["일","월","화","수","목","금","토"], id: \.self) { Text($0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }
                    ForEach(days, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text("\(day)").font(MoilTypography.regular(15))
                            if day == 5 || day == 9 { Capsule().fill(day == 5 ? Color("BrandPrimary") : Color.green).frame(width: 34, height: 5) }
                        }.frame(height: 48)
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
                HStack {
                    ForEach(["calendar","checklist","person.2","person"], id: \.self) { Image(systemName: $0).frame(maxWidth: .infinity) }
                }
                .padding(.vertical, 18)
                .foregroundStyle(MoilColor.textSecondary)
            }
        }
    }
}
