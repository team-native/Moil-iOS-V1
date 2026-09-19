import SwiftUI
import WatchKit

/// 피그마 "Apple Watch · 일정 상세" 화면입니다.
struct ScheduleDetailView: View {
    let event: EventDetail
    @State private var isAttending = false

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

                Text("두 번 탭해 응답")
                    .font(.system(size: 9))
                    .foregroundStyle(WatchColor.textSecondary)
            }
        }
        .background(WatchColor.background)
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
    private var rsvpRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
    }

    private var attendButton: some View {
        Text(isAttending ? "참석 완료" : "참석하기")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(WatchColor.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(event.owner.color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture(count: 2) {
                isAttending = true
                WKInterfaceDevice.current().play(.success)
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
                dateLabel: "7월 5일 · 일요일",
                timeLocationLabel: "오후 6:30 · 우리집",
                attendeeCountLabel: "가족 4명",
                attendees: Array(MoilWatchSampleData.members.prefix(3)),
                attendingSummary: "3명 참석"
            )
        )
    }
}
