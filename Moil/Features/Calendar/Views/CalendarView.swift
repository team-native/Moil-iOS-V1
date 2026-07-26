import SwiftUI

struct CalendarView: View {
    private let days = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    @State private var isGroupMenuPresented = false
    @State private var groupName = "우리 가족"
    @State private var isScheduleComposerPresented = false
    @State private var isMemberViewPresented = false
    @State private var isMyPagePresented = false
    @State private var isCreateGroupPresented = false
    @State private var isJoinGroupPresented = false
    @State private var isJoinProfilePresented = false

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
                        Button { isScheduleComposerPresented = true } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(MoilColor.textPrimary)
                        }
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
                    Image(systemName: "calendar").frame(maxWidth: .infinity)
                    Image(systemName: "checklist").frame(maxWidth: .infinity)
                    Button { isMemberViewPresented = true } label: {
                        Image(systemName: "person.2").frame(maxWidth: .infinity)
                    }
                    Button { isMyPagePresented = true } label: {
                        Image(systemName: "person").frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 18)
                .foregroundStyle(MoilColor.textSecondary)
            }
        }
        .sheet(isPresented: $isScheduleComposerPresented) {
            ScheduleComposerView()
                .presentationDetents([.height(463)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isMemberViewPresented) { MemberView() }
        .sheet(isPresented: $isMyPagePresented) {
            MyPageView(onCreateGroup: { isMyPagePresented = false; isCreateGroupPresented = true })
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
}

private struct ScheduleComposerView: View {
    @Environment(\.dismiss) private var dismiss
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
                Button("저장", action: dismiss.callAsFunction)
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
                    ForEach([("아빠", Color.blue), ("엄마", Color.red), ("나", Color.green), ("동생", Color.orange)], id: \.0) { member in
                        Button { toggle(member.0) } label: {
                            VStack(spacing: 6) {
                                Circle().fill(member.1).frame(width: 44, height: 44)
                                    .overlay { Image(systemName: "person.fill").foregroundStyle(.white) }
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
