import SwiftUI

struct CalendarView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let calendar = Calendar.current
    @State private var isGroupMenuPresented = false
    @State private var groupName = "우리 가족"
    @State private var isScheduleComposerPresented = false
    @State private var isMemberViewPresented = false
    @State private var isMyPagePresented = false
    @State private var isCreateGroupPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false
    @State private var shouldOpenCreateGroupAfterProfile = false
    @State private var displayedMonth = Date()
    @State private var scheduledDays: Set<Int> = [5, 9]

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var leadingBlankDays: Int {
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        return calendar.component(.weekday, from: firstDay) - 1
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).locale(Locale(identifier: "ko_KR")))
    }

    private var yearTitle: String {
        displayedMonth.formatted(.dateTime.year().locale(Locale(identifier: "ko_KR")))
    }

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
                            HStack(spacing: 8) {
                                HStack(spacing: -7) {
                                    ForEach([MoilAvatarColor.blue, MoilAvatarColor.red, MoilAvatarColor.green, MoilAvatarColor.orange], id: \.self) { color in
                                        MoilAvatar(color: color, size: 24)
                                            .overlay { Circle().stroke(MoilColor.background, lineWidth: 2) }
                                    }
                                }
                                Text(groupName)
                                    .font(MoilTypography.semibold(15))
                                    .foregroundStyle(MoilColor.textPrimary)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MoilColor.textSecondary)
                        }
                    Spacer()
                        Button { isScheduleComposerPresented = true } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(MoilColor.textPrimary)
                        }
                    }

                    if isGroupMenuPresented {
                        VStack(spacing: 0) {
                            ForEach([("우리 가족", MoilAvatarColor.blue), ("대학 동기", MoilAvatarColor.green), ("회사 팀", MoilAvatarColor.orange)], id: \.0) { group in
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
                            Divider()
                            Button {
                                isGroupMenuPresented = false
                                isJoinGroupPresented = true
                            } label: {
                                Label("그룹 참여", systemImage: "person.badge.plus")
                                    .font(MoilTypography.semibold(14))
                                    .padding(.horizontal, 14)
                                    .frame(height: 46)
                            }
                            .foregroundStyle(MoilColor.primary)
                            Button {
                                isGroupMenuPresented = false
                                isCreateGroupPresented = true
                            } label: {
                                Label("새 그룹 만들기", systemImage: "plus")
                                    .font(MoilTypography.semibold(14))
                                    .padding(.horizontal, 14)
                                    .frame(height: 46)
                            }
                            .foregroundStyle(MoilColor.primary)
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
                .padding(.top, 38)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(monthTitle).font(MoilTypography.bold(32))
                        Text(yearTitle).font(MoilTypography.regular(14)).foregroundStyle(MoilColor.textSecondary)
                    }
                    Spacer()
                    Button { moveMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                        .frame(width: 30, height: 30)
                        .background(.white)
                        .clipShape(Circle())
                    }
                    Button { moveMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                        .frame(width: 30, height: 30)
                        .background(.white)
                        .clipShape(Circle())
                    }
                    .padding(.leading, 6)
                }
                .padding(16)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(["일","월","화","수","목","금","토"], id: \.self) { Text($0).font(MoilTypography.regular(12)).foregroundStyle(MoilColor.textSecondary) }
                    ForEach(0..<leadingBlankDays, id: \.self) { _ in
                        Color.clear.frame(height: 48)
                    }
                    ForEach(1...daysInMonth, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text("\(day)").font(MoilTypography.regular(15))
                            if scheduledDays.contains(day) {
                                Capsule().fill(day == 5 ? Color("BrandPrimary") : MoilAvatarColor.green).frame(width: 34, height: 5)
                            }
                        }.frame(height: 48)
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MoilTabBar(selected: .calendar) { tab in
                switch tab {
                case .calendar: break
                case .members: isMemberViewPresented = true
                case .create: isScheduleComposerPresented = true
                case .profile: isMyPagePresented = true
                }
            }
        }
        .sheet(isPresented: $isScheduleComposerPresented) {
            ScheduleComposerView { day in
                scheduledDays.insert(day)
            }
                .presentationDetents([.height(463)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isMemberViewPresented) { MemberView() }
        .sheet(isPresented: $isMyPagePresented, onDismiss: {
            guard shouldOpenCreateGroupAfterProfile else { return }
            shouldOpenCreateGroupAfterProfile = false
            isCreateGroupPresented = true
        }) {
            MyPageView(onCreateGroup: {
                shouldOpenCreateGroupAfterProfile = true
                isMyPagePresented = false
            })
        }
        .sheet(isPresented: $isCreateGroupPresented) { CreateGroupView() }
        .sheet(isPresented: $isJoinGroupPresented) {
            GroupJoinCodeView {
                isJoinGroupPresented = false
                isJoinProfilePresented = true
            }
        }
        .sheet(isPresented: $isJoinProfilePresented) {
            GroupJoinProfileView { isJoinProfilePresented = false }
        }
    }

    private func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        scheduledDays = []
    }
}

#Preview("캘린더") {
    CalendarView()
}

private struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int) -> Void
    @State private var title = ""
    @State private var allDay = false
    @State private var selectedMembers: Set<String> = ["아빠", "나"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: dismiss.callAsFunction)
                    .foregroundStyle(MoilColor.textSecondary)
                Spacer()
                Text("새 일정").font(MoilTypography.semibold(16))
                Spacer()
                Button("저장") {
                    onSave(22)
                    dismiss()
                }
                    .font(MoilTypography.bold(16))
                    .foregroundStyle(MoilColor.primary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            TextField("일정 제목", text: $title)
                .font(MoilTypography.semibold(21))
                .padding(.horizontal, 18)
                .frame(height: 58)
                .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }

            ScheduleRow(title: "날짜", value: "7월 22일 (수)")
            HStack {
                Text("하루 종일").font(MoilTypography.regular(15))
                Spacer()
                Toggle("", isOn: $allDay).labelsHidden().tint(MoilColor.primary)
            }
            .padding(.horizontal, 18).frame(height: 50)
            .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }
            ScheduleRow(title: "시간", value: "오전 9:00 – 10:00")
            ScheduleRow(title: "위치", value: "추가", secondary: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("누구와 공유할까요")
                    .font(MoilTypography.semibold(13))
                    .foregroundStyle(MoilColor.textSecondary)
                HStack(spacing: 14) {
                    ForEach([("아빠", MoilAvatarColor.blue), ("엄마", MoilAvatarColor.red), ("나", MoilAvatarColor.green), ("동생", MoilAvatarColor.orange)], id: \.0) { member in
                        Button { toggle(member.0) } label: {
                            VStack(spacing: 6) {
                                MoilAvatar(color: member.1, size: 44)
                                    .overlay { Circle().stroke(selectedMembers.contains(member.0) ? MoilColor.primary : .clear, lineWidth: 3).padding(-4) }
                                Text(member.0).font(MoilTypography.regular(11)).foregroundStyle(MoilColor.textSecondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18).padding(.top, 16)
            Spacer()
        }
        .background(.white)
    }

    private func toggle(_ member: String) {
        if selectedMembers.contains(member) { selectedMembers.remove(member) } else { selectedMembers.insert(member) }
    }
}

private struct ScheduleRow: View {
    let title: String
    let value: String
    var secondary = false

    var body: some View {
        HStack {
            Text(title).font(MoilTypography.regular(15))
            Spacer()
            Text(value).font(MoilTypography.regular(15)).foregroundStyle(secondary ? MoilColor.textTertiary : MoilColor.textSecondary)
        }
        .padding(.horizontal, 18).frame(height: 46)
        .overlay(alignment: .bottom) { Divider().padding(.horizontal, 18) }
    }
}
