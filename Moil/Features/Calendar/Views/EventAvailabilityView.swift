import SwiftUI

/// 일정 하나에 대해 내가 가능한 시간대를 등록하고, 가족들이 등록한 시간대를 겹쳐서
/// 보여주는 화면입니다. 등록은 이 화면(아이폰 앱)에서만 하고, 워치는 결과만 읽어서 보여줍니다.
struct EventAvailabilityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: MoilSessionStore

    let eventId: String
    let eventTitle: String
    /// "yyyy-MM-dd" 형식입니다.
    let date: String

    @State private var mySlots: [MoilAvailabilityTimeSlot] = []
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(3600)
    @State private var summary: MoilAvailabilitySummary?
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    mySlotsSection
                    addSlotSection
                    if let errorMessage {
                        Text(errorMessage)
                            .font(MoilTypography.regular(12))
                            .foregroundStyle(MoilColor.error)
                    }
                    summarySection
                }
                .padding(20)
            }
            .background(MoilColor.background)
            .navigationTitle("가능 시간 입력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eventTitle)
                .font(MoilTypography.bold(20))
                .foregroundStyle(MoilColor.textPrimary)
            Text(date.replacingOccurrences(of: "-", with: "."))
                .font(MoilTypography.regular(13))
                .foregroundStyle(MoilColor.textSecondary)
        }
    }

    private var mySlotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내가 가능한 시간")
                .font(MoilTypography.semibold(14))
                .foregroundStyle(MoilColor.textPrimary)

            if mySlots.isEmpty {
                Text("아직 등록한 시간대가 없어요.")
                    .font(MoilTypography.regular(13))
                    .foregroundStyle(MoilColor.textTertiary)
            } else {
                ForEach(mySlots) { slot in
                    HStack {
                        Text("\(slot.startTime) – \(slot.endTime)")
                            .font(MoilTypography.regular(14))
                            .foregroundStyle(MoilColor.textPrimary)
                        Spacer()
                        Button {
                            mySlots.removeAll { $0.id == slot.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(MoilColor.textTertiary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(MoilColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var addSlotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("시간대 추가")
                .font(MoilTypography.semibold(14))
                .foregroundStyle(MoilColor.textPrimary)

            HStack(spacing: 10) {
                DatePicker("시작", selection: $draftStart, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("–")
                    .foregroundStyle(MoilColor.textSecondary)
                DatePicker("종료", selection: $draftEnd, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Spacer()
                Button("추가", action: addDraftSlot)
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(MoilColor.primary)
                    .disabled(draftEnd <= draftStart)
            }

            MoilPrimaryButton(title: "저장", isEnabled: !isSaving, isLoading: isSaving, action: save)
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 10) {
                Text("가족 응답 현황 · \(summary.respondedCount)/\(summary.participantCount)명")
                    .font(MoilTypography.semibold(14))
                    .foregroundStyle(MoilColor.textPrimary)

                if summary.timeSlots.isEmpty {
                    Text("아직 아무도 등록하지 않았어요.")
                        .font(MoilTypography.regular(13))
                        .foregroundStyle(MoilColor.textTertiary)
                } else {
                    ForEach(summary.timeSlots) { slot in
                        HStack {
                            Text("\(slot.startTime) – \(slot.endTime)")
                                .font(MoilTypography.regular(13))
                                .foregroundStyle(MoilColor.textPrimary)
                            Spacer()
                            Text(slot.isAvailableForEveryone ? "모두 가능" : "\(slot.availableCount)명 가능")
                                .font(MoilTypography.semibold(12))
                                .foregroundStyle(slot.isAvailableForEveryone ? MoilColor.success : MoilColor.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(MoilColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func addDraftSlot() {
        let slot = MoilAvailabilityTimeSlot(
            startTime: Self.timeFormatter.string(from: draftStart),
            endTime: Self.timeFormatter.string(from: draftEnd)
        )
        guard !mySlots.contains(slot) else { return }
        mySlots.append(slot)
        mySlots.sort { $0.startTime < $1.startTime }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let service = sessionStore.service()
            async let mine = service.myAvailability(eventId: eventId, date: date)
            async let summaryTask = service.availabilitySummary(eventId: eventId, date: date)
            let (myResponse, summaryResponse) = try await (mine, summaryTask)
            mySlots = myResponse.timeSlots
            summary = summaryResponse
        } catch {
            guard !error.isRequestCancellation else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                let service = sessionStore.service()
                try await service.saveAvailability(eventId: eventId, date: date, timeSlots: mySlots)
                summary = try await service.availabilitySummary(eventId: eventId, date: date)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    EventAvailabilityView(eventId: "1", eventTitle: "엄마 생일", date: "2026-09-20")
        .environmentObject(MoilSessionStore())
}
