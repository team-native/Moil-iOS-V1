import SwiftUI

/// 캘린더 화면들이 함께 쓰는 일정 모델입니다.
struct CalendarEvent: Identifiable, Equatable {
    /// 좁은 날짜 칸에서 말줄임표가 생기지 않도록 공백 포함 앞 여섯 글자만 씁니다.
    var shortTitle: String { String(title.prefix(6)) }

    let id: String
    let day: Int
    /// 여러 날에 걸친 일정을 대비해 마지막 날을 따로 둡니다.
    /// 서버가 아직 종료 날짜를 주지 않아 지금은 항상 시작일과 같습니다.
    let endDay: Int
    let owner: String
    let title: String
    let date: String
    let color: Color
    let isAllDay: Bool
    let startTime: String?
    let endTime: String?
    let location: String?
    let memo: String?
    let members: [CalendarEventMember]

    var memberIDs: [Int] { members.compactMap { Int($0.id) } }

    /// "10:00 – 11:30"처럼 한 줄로 보여 줄 시간 문자열입니다.
    var timeRangeText: String {
        guard !isAllDay, let startTime else { return "하루 종일" }
        guard let endTime else { return startTime }
        return "\(startTime) – \(endTime)"
    }

    init?(remote: MoilRemoteEvent) {
        guard let normalizedDate = MoilCalendarDate.normalizedString(from: remote.date),
              let eventDay = MoilCalendarDate.day(from: normalizedDate) else { return nil }
        id = remote.id
        day = eventDay
        endDay = eventDay
        owner = remote.ownerName ?? ""
        title = remote.title
        date = normalizedDate
        color = MoilAvatarColor.color(for: remote.colorId)
        isAllDay = remote.isAllDay
        startTime = remote.startTime
        endTime = remote.endTime
        location = remote.location
        memo = remote.memo
        members = remote.members.map {
            CalendarEventMember(
                id: $0.id ?? "",
                nickname: $0.nickname ?? "",
                color: MoilAvatarColor.color(for: $0.colorId)
            )
        }
    }
}

struct CalendarEventMember: Identifiable, Equatable {
    let id: String
    let nickname: String
    let color: Color
}

/// API의 `yyyy-MM-dd` 값과 ISO-8601 날짜 시간을 모두 로컬 달력 날짜로 정규화합니다.
/// 서버가 UTC 날짜 시간을 반환해도 화면과 다음 수정 요청에서 하루가 밀리지 않게 합니다.
enum MoilCalendarDate {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func string(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func normalizedString(from value: String) -> String? {
        if let dateOnly = dateOnlyComponents(from: value) {
            return string(year: dateOnly.year, month: dateOnly.month, day: dateOnly.day)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: value) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: value)
        }() ?? localDate(from: value)
        guard let date else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        return string(year: year, month: month, day: day)
    }

    static func day(from date: String) -> Int? {
        dateOnlyComponents(from: date)?.day
    }

    /// "7월 15일 (월)"처럼 시트 제목에 쓰는 문자열입니다.
    static func title(year: Int, month: Int, day: Int) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components) else { return "\(month)월 \(day)일" }
        let weekday = date.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "ko_KR")))
        return "\(month)월 \(day)일 (\(weekday))"
    }

    static func isToday(year: Int, month: Int, day: Int) -> Bool {
        let today = calendar.dateComponents([.year, .month, .day], from: .now)
        return today.year == year && today.month == month && today.day == day
    }

    private static func dateOnlyComponents(from value: String) -> (year: Int, month: Int, day: Int)? {
        // 서버가 `yyyy-MM-dd` 또는 `yyyy-MM-ddTHH:mm:ssZ`를 반환해도
        // 원문 날짜를 우선 사용해 UTC 변환으로 전날로 밀리는 일을 막습니다.
        let datePrefix = String(value.prefix(10))
        let parts = datePrefix.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              (1...12).contains(month),
              (1...31).contains(day) else { return nil }
        return (year, month, day)
    }

    private static func localDate(from value: String) -> Date? {
        let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"]

        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .autoupdatingCurrent
            formatter.dateFormat = format

            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
}
