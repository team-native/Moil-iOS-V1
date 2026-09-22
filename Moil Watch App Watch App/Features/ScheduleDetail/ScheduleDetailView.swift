import SwiftUI
import WatchKit

/// 피그마 "Apple Watch · 일정 상세" 화면입니다.
struct ScheduleDetailView: View {
    let event: EventDetail
    /// 가족이 아이폰 앱에서 등록한 가능 시간대를 읽기 전용으로 불러옵니다. 워치에서는
    /// 등록하지 않고 결과만 보여줍니다.
    let loadAvailability: () async -> MoilAvailabilitySummary?

    @State private var isAttending = false
    @State private var availability: MoilAvailabilitySummary?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text("\(event.owner.name) 일정")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WatchColor.onAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(event.owner.color)
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Text(event.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(WatchColor.textPrimary)

                infoCard

                rsvpRow

                attendButton

                availabilitySection
            }
        }
        .background(WatchColor.background)
        .task {
            availability = await loadAvailability()
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.dateLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchColor.textPrimary)
            Text(event.timeLocationLabel)
                .font(.system(size: 10))
                .foregroundStyle(WatchColor.textSecondary)
            Text(event.attendeeCountLabel)
                .font(.system(size: 10))
                .foregroundStyle(WatchColor.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    /// 참석자가 많아 화면 너비를 넘어가도 잘리지 않도록, 이 줄만 옆으로 스크롤할 수 있게 합니다.
    /// ScrollView는 `.focusable(false)`를 줘도 크라운에 반응해(크라운 연결이 SwiftUI 포커스가
    /// 아니라 ScrollView 자체에 있음) 화면에 들어가자마자 크라운만 돌려도 이 줄이 밀렸습니다.
    /// 크라운이 아예 닿을 수 없는 손가락 드래그 전용 스크롤로 대체합니다.
    private var rsvpRow: some View {
        CrownSafeHorizontalScroll {
            HStack(spacing: 6) {
                ForEach(event.attendees) { attendee in
                    Text(attendee.initial)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(WatchColor.onAccent)
                        .frame(width: 26, height: 26)
                        .background(attendee.color)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                Text(event.attendingSummary)
                    .font(.system(size: 10))
                    .foregroundStyle(WatchColor.textSecondary)
            }
        }
        .frame(height: 26)
    }

    private var attendButton: some View {
        Button {
            isAttending.toggle()
            WKInterfaceDevice.current().play(isAttending ? .success : .click)
        } label: {
            Text(isAttending ? "취소하기" : "참석하기")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isAttending ? WatchColor.textPrimary : WatchColor.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isAttending ? WatchColor.surface : event.owner.color)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var availabilitySection: some View {
        if let availability, !availability.timeSlots.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("가족 가능 시간 · \(availability.respondedCount)/\(availability.participantCount)명")
                    .font(.system(size: 9))
                    .foregroundStyle(WatchColor.textSecondary)
                    .padding(.top, 4)

                ForEach(availability.timeSlots) { slot in
                    HStack(spacing: 6) {
                        Text("\(slot.startTime)–\(slot.endTime)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WatchColor.textPrimary)
                        Spacer(minLength: 0)
                        Text(slot.isAvailableForEveryone ? "모두 가능" : "\(slot.availableCount)명")
                            .font(.system(size: 9))
                            .foregroundStyle(WatchColor.textSecondary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WatchColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleDetailView(
            event: EventDetail(
                id: "1",
                owner: MoilWatchSampleData.members[0],
                title: "엄마 생일",
                date: "2026-07-05",
                dateLabel: "7월 5일 · 일요일",
                timeLocationLabel: "오후 6:30 · 우리집",
                attendeeCountLabel: "가족 4명",
                attendees: Array(MoilWatchSampleData.members.prefix(3)),
                attendingSummary: "3명 참석"
            ),
            loadAvailability: { nil }
        )
    }
}
