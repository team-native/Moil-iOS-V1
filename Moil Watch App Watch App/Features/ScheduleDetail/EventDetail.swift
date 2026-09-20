import SwiftUI

struct EventDetail: Identifiable, Hashable {
    let id: String
    let owner: FamilyMember
    let title: String
    /// "yyyy-MM-dd" 형식입니다. 가족 가능 시간 조회에 씁니다.
    let date: String
    let dateLabel: String
    let timeLocationLabel: String
    let attendeeCountLabel: String
    let attendees: [FamilyMember]
    let attendingSummary: String
}
