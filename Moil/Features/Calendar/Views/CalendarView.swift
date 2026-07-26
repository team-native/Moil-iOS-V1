import SwiftUI

struct CalendarView: View {
    private let days = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    @State private var isGroupMenuPresented = false
    @State private var groupName = "우리 가족"

    var body: some View {
        ZStack {
            MoilColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isGroupMenuPresented.toggle()
                            }
                        } label: {
                            Label(groupName, systemImage: "person.2.fill")
                                .font(MoilTypography.semibold(15))
                                .foregroundStyle(MoilColor.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                    Spacer()
                        Image(systemName: "bell")
                    }

                    if isGroupMenuPresented {
                        VStack(spacing: 0) {
                            ForEach([("우리 가족", Color.blue), ("대학 동기", Color.green), ("회사 팀", Color.orange)], id: \.0) { group in
                                Button {
                                    groupName = group.0
                                    isGroupMenuPresented = false
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle().fill(group.1).frame(width: 8, height: 8)
                                        Text(group.0).font(MoilTypography.semibold(14))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 46)
                                }
                                .foregroundStyle(MoilColor.textPrimary)
                                if group.0 != "회사 팀" { Divider() }
                            }
                        }
                        .frame(width: 180)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                        .padding(.top, 32)
                        .zIndex(1)
                    }
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
